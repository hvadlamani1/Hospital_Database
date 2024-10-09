import java.util.Scanner;

public class Main {

    public static void main(String[] args) {
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
        if(argument == 0) {
            System.out.println("1- Report Patients Basic Information\n " +
                    "2- Report Doctors Basic Information\n" +
                    "3- Report Admissions Information\n" +
                    "4- Update Admissions Payment");
        }

        else if(argument == 1) {
            System.out.println("Enter Patient SSN: ");
            String pSSN = scanner.nextLine();
        }

        else if(argument == 2) {
            System.out.println("Enter Doctor ID: ");
            String dID = scanner.nextLine();
        }

        else if(argument == 3) {
            System.out.println("Enter Admission Number: ");
            String adNum = scanner.nextLine();
        }

        else if(argument == 4) {
            System.out.println("Enter Admission Number: ");
            String adNum = scanner.nextLine();

            System.out.println("Enter the new total payment: ");
            Double totalPayment = scanner.nextDouble();
        }
        else{
            System.err.println("Invalid argument");
        }
    }
}