import java.sql.DriverManager;
import java.util.Scanner;
import java.sql.Connection;
import java.sql.*;

public class Main {

    public static void main(String[] args) throws SQLException {
        Scanner scanner = new Scanner(System.in);

        if(args.length < 2){
            System.err.println("Did not include two arguments");
        }
        String username = args[0];
        String password = args[1];

        int argument = 0;

        if(args.length > 2) {
            argument = Integer.parseInt(args[2]);
        }

        //connect to database
        Connection connection = DriverManager.getConnection(
                "jdbc:oracle:thin:@oracle.wpi.edu:1521:orcl",
                "XXXXX",
                "XXXXX");

        if(argument == 0) {
            System.out.println("1- Report Patients Basic Information\n " +
                    "2- Report Doctors Basic Information\n" +
                    "3- Report Admissions Information\n" +
                    "4- Update Admissions Payment");
        }

        else if(argument == 1) {
            System.out.print("Enter Patient SSN: ");
            String pSSN = scanner.nextLine();

            PreparedStatement ps = connection.prepareStatement("select SSN, FIRSTNAME, LASTNAME, ADDRESS from Patient where SSN = ?");
            ps.setString(1, pSSN);
            ResultSet rs = ps.executeQuery();
            while(rs.next()) {
                System.out.println("Patient SSN: " + rs.getString("SSN"));
                System.out.println("Patient First Name: " + rs.getString("FIRSTNAME"));
                System.out.println("Patient Last Name: " + rs.getString("LASTNAME"));
                System.out.println("Patient Address: " + rs.getString("ADDRESS"));
            }

        }

        else if(argument == 2) {
            System.out.print("Enter Doctor ID: ");
            String dID = scanner.nextLine();

            PreparedStatement ps = connection.prepareStatement(
                    "SELECT E.EMPLOYEEID, E.FNAME, E.LNAME, D.GENDER, D.GRADUATEDFROM, D.SPECIALTY " +
                            "FROM Doctor D " +
                            "JOIN Employee E ON D.EmployeeID = E.EmployeeID " +
                            "WHERE D.EMPLOYEEID = ?"
            );

            ps.setString(1, dID);

            ResultSet rs = ps.executeQuery();
            while(rs.next()) {
                System.out.println("Doctor ID: " + rs.getString("EmployeeID"));
                System.out.println("Doctor First Name: " + rs.getString("FNAME"));
                System.out.println("Doctor Last Name: " + rs.getString("LNAME"));
                System.out.println("Doctor Gender: " + rs.getString("GENDER"));
                System.out.println("Doctor Graduated From: " + rs.getString("GRADUATEDFROM"));
                System.out.println("Doctor Speciality: " + rs.getString("SPECIALTY"));
            }

        }

        else if(argument == 3) {
            System.out.print("Enter Admission Number: ");
            String adNum = scanner.nextLine();
            PreparedStatement ps = connection.prepareStatement("SELECT a.AdmissionNum, a.PatientSSN, a.AdmissionDate, a.TotalPayment " +
                    "FROM Admission a WHERE a.AdmissionNum = ?"
            );
            ps.setString(1, adNum);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                // Print basic admission details
                System.out.println("Admission Number: " + rs.getString("AdmissionNum"));
                System.out.println("Patient SSN: " + rs.getString("PatientSSN"));
                System.out.println("Admission Date (start date): " + rs.getDate("AdmissionDate"));
                System.out.println("Total Payment: " + rs.getDouble("TotalPayment"));


                // Query to retrieve room details
                PreparedStatement roomStmt = connection.prepareStatement(
                        "SELECT RoomNum, StartDate, EndDate FROM StayIn WHERE AdmissionNum = ?");
                roomStmt.setString(1, adNum);
                ResultSet roomRs = roomStmt.executeQuery();


                System.out.println("Rooms:");
                while (roomRs.next()) {
                    System.out.println("RoomNum: " + roomRs.getString("RoomNum") +
                            " FromDate: " + roomRs.getDate("StartDate") +
                            " ToDate: " + roomRs.getDate("EndDate"));
                }


                // Query to retrieve unique doctors who examined the patient
                PreparedStatement doctorStmt = connection.prepareStatement(
                        "SELECT DISTINCT DoctorID FROM Examine WHERE AdmissionNum = ?");
                doctorStmt.setString(1, adNum);
                ResultSet doctorRs = doctorStmt.executeQuery();


                System.out.println("Doctors examined the patient in this admission:");
                while (doctorRs.next()) {
                    System.out.println("Doctor ID: " + doctorRs.getString("DoctorID"));
                }
            } else {
                System.out.println("Admission not found.");
            }

        }

        else if(argument == 4) {
            System.out.print("Enter Admission Number: ");
            String adNum = scanner.nextLine();

            System.out.print("Enter the new total payment: ");
            Double totalPayment = scanner.nextDouble();
        }
        else{
            System.err.println("Invalid argument");
        }
    }
}