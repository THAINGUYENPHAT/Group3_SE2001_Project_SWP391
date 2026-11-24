package service;

import java.util.Locale;
import java.util.regex.Pattern;

import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.parser.Parser;
import org.jsoup.safety.Safelist;

public final class ProductDescriptionFormatter {

    private static final Safelist SAFE_HTML
            = Safelist.relaxed()
                    .addTags(
                            "s",
                            "del",
                            "ins",
                            "mark",
                            "hr",
                            "figure",
                            "figcaption"
                    )
                    .addAttributes(
                            "a",
                            "title"
                    )
                    .addAttributes(
                            "img",
                            "title",
                            "loading"
                    )
                    .addAttributes(
                            "th",
                            "scope"
                    )
                    .addProtocols(
                            "a",
                            "href",
                            "http",
                            "https",
                            "mailto"
                    )
                    .addProtocols(
                            "img",
                            "src",
                            "http",
                            "https"
                    )
                    .preserveRelativeLinks(true);

    private static final Pattern HTML_TAG
            = Pattern.compile(
                    "(?i)<\\s*/?\\s*"
                    + "(?:h[1-6]|p|div|span|br|ul|ol|li|"
                    + "strong|em|b|i|u|s|del|ins|mark|"
                    + "a|img|table|thead|tbody|tfoot|"
                    + "tr|td|th|blockquote|pre|code|"
                    + "figure|figcaption|hr)\\b"
            );

    private ProductDescriptionFormatter() {
    }

    public static String toSafeHtml(String input) {

        if (input == null || input.trim().isEmpty()) {
            return "";
        }

        String html = input;

        html = html.replace('\u00A0', ' ')
                .replaceAll(
                        "(?i)&amp;nbsp;|&nbsp;|"
                        + "&#0*160;|&#x0*a0;",
                        " "
                );

        String lower = html.toLowerCase(Locale.ROOT);

        if (lower.contains("&lt;")
                || lower.contains("&#60;")
                || lower.contains("&#x3c;")) {

            String decoded
                    = Parser.unescapeEntities(html, false);

            if (HTML_TAG.matcher(decoded).find()) {
                html = decoded;
            }
        }

        Document.OutputSettings settings
                = new Document.OutputSettings()
                        .prettyPrint(false);

        if (!HTML_TAG.matcher(html).find()) {

            String safeText = Jsoup.clean(
                    html,
                    "",
                    Safelist.none(),
                    settings
            );

            return safeText
                    .replace("\r\n", "\n")
                    .replace("\r", "\n")
                    .replace("\n", "<br>");
        }

        String cleanedHtml = Jsoup.clean(
                html,
                "",
                SAFE_HTML,
                settings
        );

        Document document
                = Jsoup.parseBodyFragment(cleanedHtml);

        document.outputSettings(settings);

        for (Element link
                : document.select("a[href]")) {

            link.attr("target", "_blank");

            link.attr(
                    "rel",
                    "noopener noreferrer"
            );
        }

        return document.body().html();
    }
}
