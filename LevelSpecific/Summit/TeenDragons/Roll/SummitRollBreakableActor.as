class ASummitRollBreakableActor : ABreakableActor
{
	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent RollResponseComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bUseDefaultSettings = false;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bUseRollHitLocation = true;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = !bUseDefaultSettings, EditConditionHides))
	bool bUseRollSpeedAsBreakForce = true;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = !bUseDefaultSettings, EditConditionHides))
	float BreakRadius = 999999999.0;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = !bUseDefaultSettings, EditConditionHides))
	float Scatter = 0.5;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		RollResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");		
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnHitByRoll(FRollParams Params)
	{
		if(bUseDefaultSettings)
		{
			if(bUseRollHitLocation)
				BreakableComponent.BreakWithDefaultAt(Params.HitLocation);
			else
				BreakableComponent.BreakWithDefault();
		}
		else
		{
			FVector RollHitLocation = bUseRollHitLocation ? Params.HitLocation : BreakableComponent.BreakLocation;
			FVector BreakForce = bUseRollSpeedAsBreakForce ? Params.RollDirection * Params.SpeedTowardsImpact : BreakableComponent.ForceDirection;
			
			BreakableComponent.BreakAt(RollHitLocation, BreakRadius, BreakForce, Scatter);
		}
	}
};