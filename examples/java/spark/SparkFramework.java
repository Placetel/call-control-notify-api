import spark.Request;
import spark.Response;

import javax.servlet.MultipartConfigElement;

import static spark.Spark.*;

public class Main {
    public static void main(String[] args) {
        post("/event", (Request request, Response response) -> {
            String event;
            request.attribute("org.eclipse.jetty.multipartConfig", new MultipartConfigElement("/temp"));
            event = request.queryParams("event");
            if (event.equals("IncomingCall")) {
                return "ok";
            }
            return null;
        });
    }
}
