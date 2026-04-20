class DashboardModel{
  String? todayDate;
  int? totalTodayAppointment;
  int? totalAppointments;
  int? totalPendingAppointment;
  int? totalConfirmedAppointment;
  int? totalRejectedAppointment;
  int? totalCancelledAppointment;
  int? totalCompletedAppointment;
  int? totalVisitedAppointment;
  int? totalUpcomingAppointments;

  DashboardModel({
    this.todayDate,
    this.totalTodayAppointment,
    this.totalAppointments,
    this.totalPendingAppointment,
    this.totalConfirmedAppointment,
    this.totalRejectedAppointment,
    this.totalCancelledAppointment,
    this.totalCompletedAppointment,
    this.totalVisitedAppointment,
    this.totalUpcomingAppointments,
  });

  factory DashboardModel.fromJson(Map<String,dynamic> json){
    return DashboardModel(
      todayDate: json['today_date'] ,
      totalTodayAppointment: json['total_today_appointment'],
      totalAppointments: json['total_appointments'],
      totalPendingAppointment: json['total_pending_appointment'] ,
      totalConfirmedAppointment: json['total_confirmed_appointment'],
      totalRejectedAppointment: json['total_rejected_appointment'] ,
      totalCancelledAppointment: json['total_cancelled_appointment'] ,
      totalCompletedAppointment: json['total_completed_appointment'],
      totalVisitedAppointment: json['total_visited_appointment'],
      totalUpcomingAppointments: json['total_upcoming_appointments']

    );
  }

}