class UWindJavelinAutoAimTargetComponent : UAutoAimTargetComponent
{
    default TargetableCategory = WindJavelin::TargetableCategory;
	default UsableByPlayers = WindJavelin::SelectPlayer;
	default AutoAimMaxAngle = 5.0;
	default MaximumDistance = WindJavelin::DefaultAutoAimDistance;
}