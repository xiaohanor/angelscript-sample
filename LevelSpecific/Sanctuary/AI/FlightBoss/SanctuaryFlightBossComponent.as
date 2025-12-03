enum ESanctuaryFlightBossAttack
{
	None,
	FireBall,
	TentacleSweep,
	TentacleSlash,
	TentacleStab,
}

class USanctuaryFlightBossComponent : UActorComponent
{
	float FindTargetPauseDuration = 3.0;
	ESanctuaryFlightBossAttack CurrentAttack = ESanctuaryFlightBossAttack::None;
	UBasicBehaviourComponent BehaviourComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BehaviourComp = UBasicBehaviourComponent::Get(Owner);	
	}

	void SwitchTarget(float PauseDuration)
	{
		FindTargetPauseDuration = PauseDuration;
	}

	FVector GetPredictedTargetLocation(AHazeActor Target, FVector AttackOrigin, float AttackSpeed) const
	{
		FVector TargetLoc = Target.ActorCenterLocation;	
		float PredictionTime = AttackOrigin.Distance(TargetLoc) / Math::Max(100.0, AttackSpeed);
		
		// TODO: Do proper predict along cylinder!
		return TargetLoc + Target.ActorVelocity * PredictionTime; 
	}
}

