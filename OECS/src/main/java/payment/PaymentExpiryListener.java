package payment;

import dao.PaymentDAO;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import java.util.logging.Level;
import java.util.logging.Logger;

@WebListener
public class PaymentExpiryListener
        implements ServletContextListener {

    private static final Logger LOGGER =
            Logger.getLogger(
                    PaymentExpiryListener.class.getName()
            );

    private ScheduledExecutorService worker;

    // Khoi dong job khi ung dung bat dau chay
    @Override
    public void contextInitialized(ServletContextEvent event) {

        worker = Executors.newSingleThreadScheduledExecutor(
                runnable -> {
                    Thread thread = new Thread(
                            runnable,
                            "oecs-payment-expiry"
                    );

                    thread.setDaemon(true);

                    return thread;
                }
        );

        // Quet ngay khi khoi dong, sau do moi 30 giay
        worker.scheduleWithFixedDelay(
                () -> {
                    try {
                        PaymentDAO paymentDAO =
                                new PaymentDAO();

                        paymentDAO.expireBatch();

                    } catch (Exception e) {
                        LOGGER.log(
                                Level.SEVERE,
                                "Không xử lý được đơn hết hạn. "
                                + "Sẽ thử lại ở lần quét tiếp theo.",
                                e
                        );
                    }
                },
                0,
                30,
                TimeUnit.SECONDS
        );
    }

    // Dung job khi ung dung tat hoac deploy lai
    @Override
    public void contextDestroyed(ServletContextEvent event) {

        if (worker != null) {
            worker.shutdownNow();
        }
    }
}