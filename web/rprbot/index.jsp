<%@ page import="javax.xml.transform.OutputKeys" %>
<%@ page import="javax.xml.transform.Transformer" %>
<%@ page import="javax.xml.transform.TransformerException" %>
<%@ page import="javax.xml.transform.TransformerFactory" %>
<%@ page import="javax.xml.transform.stream.StreamResult" %>
<%@ page import="javax.xml.transform.stream.StreamSource" %>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.io.IOException" %>
<%@ page import="java.io.InputStreamReader" %>
<%@ page import="java.io.OutputStream" %>
<%@ page import="java.io.StringReader" %>
<%@ page import="java.io.StringWriter" %>
<%@ page import="java.net.HttpURLConnection" %>
<%@ page import="java.net.URL" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page contentType="application/xml; charset=UTF-8" language="java" %>


<%!

  String prettify(String xml) throws TransformerException {
    final TransformerFactory factory = TransformerFactory.newInstance();
    factory.setAttribute("indent-number", 2);

    final Transformer transformer =
        factory.newTransformer();

    transformer.setOutputProperty(OutputKeys.INDENT, "yes");
    transformer.setOutputProperty(OutputKeys.METHOD, "xml");
    transformer.setOutputProperty(OutputKeys.MEDIA_TYPE, "text/xml");

    final StreamResult result = new StreamResult(new StringWriter());
    transformer.transform(new StreamSource(new StringReader(xml)), result);

    return result.getWriter().toString();
  }

  String post(String licenseNumber) {
    try {
      final String xml = "<pre attributes=\"html.escape: false\">" +
          prettify(post0(licenseNumber))
              .replace("<?xml version=\"1.0\" encoding=\"UTF-8\"?>", "")
              .replace("<", "&lt;")
              .replace(">", "&gt;")
          + "</pre>";

      return "Данные по разрешению <b>" + licenseNumber + "</b>:<br/><br/>" +
          xml;

    } catch (Exception e) {
      e.printStackTrace();
      return "При запросе разрешения " + licenseNumber + " произошла неведомая ошибка: "
          + e.getMessage();
    }
  }

  String post0(String licenseNumber) throws IOException {

    System.setProperty("sun.net.http.allowRestrictedHeaders", "true");

    final HttpURLConnection conn = (HttpURLConnection)
        new URL("http://172.16.250.142/services/ws/ParkingService")
            .openConnection();

    try {

      final String msg =
          "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"\n" +
              "                       xmlns:par=\"http://asguf.mos.ru/rkis_gu/parkings/\">\n" +
              "     <soapenv:Header/>\n" +
              "     <soapenv:Body>\n" +
              "       <par:findParkings>\n" +
              "         <par:req>\n" +
              "            <par:LicenseNum>" + licenseNumber + "</par:LicenseNum>\n" +
              "         </par:req>\n" +
              "       </par:findParkings>\n" +
              "     </soapenv:Body>\n" +
              "     </soapenv:Envelope>";

      conn.setRequestProperty("Host", "corerpr");
      conn.setRequestProperty("Content-type", "text/xml;charset=UTF-8");
      conn.setRequestProperty("SOAPAction",
          "http://asguf.mos.ru/rkis_gu/parkings/IService/findParkings");

      conn.setRequestMethod("POST");
      conn.setDoOutput(true);
      conn.setDoInput(true);

      final OutputStream reqStream = conn.getOutputStream();
      reqStream.write(msg.getBytes(StandardCharsets.UTF_8));
      reqStream.close();

      final StringBuilder buf = new StringBuilder();

      final BufferedReader in =
          new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));
      try {
        String line;
        while ((line = in.readLine()) != null) {
          buf.append(line).append("\n");
        }

      } finally {
        in.close();
      }

      return buf.toString();

    } finally {

      if (conn != null) {
        conn.disconnect();
      }
    }
  }

%>

<%

  final String text;

  String command = request.getParameter("value");
  if (command != null) {
    command = new String(command.getBytes(StandardCharsets.ISO_8859_1), StandardCharsets.UTF_8);
    command = command.trim();
  }

  if (command == null || command.isEmpty()) {
    text = null;

  } else if (command.startsWith("Список изменений:")) {
    String license = command.replaceFirst("Список изменений:", "");
    license = license.replaceAll("[^0-9\\-]", "");

    text = post(license);

  } else {
    text = null;
  }

  request.setAttribute("text", text);
%>


<% if (text == null) { %>

  <page version="2.0">
    <div>
      <input navigationId="submit" name="value"/>
    </div>
    <navigation id="submit">
      <link pageId="index.jsp">Ok</link>
    </navigation>
  </page>

<% } else {%>

  <page version="2.0">
    <div>${text}</div>

    <div>
      <input navigationId="submit" name="value"/>
    </div>
    <navigation id="submit">
      <link pageId="index.jsp">Ok</link>
    </navigation>
  </page>

<% }%>

