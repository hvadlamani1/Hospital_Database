public class Main {
    public static void main(String[] args) {
        if(args.length < 2){
            System.err.println("Did not include two arguments");
        }
        String username = args[0];
        String password = args[1];
        int argument = Integer.parseInt(args[2]);

        System.out.println("1- Report Patients Basic Information\n " +
                "2- Report Doctors Basic Information\n" +
                "3- Report Admissions Information\n" +
                "4- Update Admissions Payment");
    }
}