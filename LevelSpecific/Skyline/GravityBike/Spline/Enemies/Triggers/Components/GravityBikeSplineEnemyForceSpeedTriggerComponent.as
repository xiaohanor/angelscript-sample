UCLASS(NotBlueprintable, HideCategories = "Debug Rendering Activation Cooking Tags LOD Collision Rendering Navigation")
class UGravityBikeSplineEnemyForceSpeedTriggerComponent : UGravityBikeSplineEnemyTriggerComponent
{
	default StartColor = ColorDebug::Green;
	default EndColor = ColorDebug::Jade;
	default bUseEndExtent = true;
	default EndExtent = 1000;

    UPROPERTY(EditAnywhere, Category = "Enemy Force Speed Trigger")
	bool bFullThrottle = false;
	
    UPROPERTY(EditAnywhere, Category = "Enemy Force Speed Trigger", Meta = (EditCondition = "!bFullThrottle"))
    float ForcedSpeed = 5000;

	void OnEnemyEnter(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		auto MoveComp = UGravityBikeSplineEnemyMovementComponent::Get(TriggerUserComp.Owner);
		if(MoveComp == nullptr)
			return;

		if(bFullThrottle)
			MoveComp.ForceSpeed.Apply(MoveComp.MaximumSpeed, this);
		else
			MoveComp.ForceSpeed.Apply(ForcedSpeed, this);
	}

	void OnEnemyExit(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport) override
	{
		auto MoveComp = UGravityBikeSplineEnemyMovementComponent::Get(TriggerUserComp.Owner);
		if(MoveComp == nullptr)
			return;

		MoveComp.ForceSpeed.Clear(this);
	}
};