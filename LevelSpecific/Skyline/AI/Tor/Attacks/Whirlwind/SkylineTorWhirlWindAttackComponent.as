class USkylineTorWhirlwindAttackComponent : UActorComponent
{
	void Swing()
	{
		USkylineTorEventHandler::Trigger_OnWhirlwindAttackSwing(Cast<AHazeActor>(Owner));
	}
}