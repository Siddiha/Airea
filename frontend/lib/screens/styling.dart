import "package:flutter/material.dart";

class VitalCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;
  final IconData icon;
  final Color color;
  final double Cardheight;

  const VitalCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.icon,
    required this.color,
    required this.Cardheight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Cardheight,
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Icon(icon, size: 30),
          const SizedBox(width: 8),
          Column(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}

class vitalCardWithButton extends StatelessWidget{
  final String title;
  final String value; 
  final String status; 
  final String btnText; 
  final Color statusColor;
  //final IconData icon;
  final Color color;
  final double Cardheight;

 

  const vitalCardWithButton({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.btnText,
    required this.statusColor,
    //required this.icon,
    required this.color,
    required this.Cardheight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height:Cardheight ,
      margin: EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 18, color: statusColor, fontWeight: FontWeight.bold)),
              Text(status, style: TextStyle(color: statusColor)),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 194, 255, 248), shape: StadiumBorder()),
            child: Text(btnText),
          )
        ],
      ),
    );
  }
}


 