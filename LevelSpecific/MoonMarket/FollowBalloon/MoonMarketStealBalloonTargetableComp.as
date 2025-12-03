class UMoonMarketStealBalloonTargetableComp : UTargetableComponent
{
	default TargetableCategory = ActionNames::Interaction;

	UPROPERTY(EditAnywhere)
	float VisibleRange = 2000.0;
	
	UPROPERTY(EditAnywhere)
	float TargetableRange = 300.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		DisableForPlayer(Cast<AHazePlayerCharacter>(Owner), this);
		AttachToComponent(Cast<AHazePlayerCharacter>(Owner).Mesh, n"LeftHand");
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		UMoonMarketHoldBalloonComp BalloonComp = UMoonMarketHoldBalloonComp::Get(Owner);

		if(BalloonComp.CurrentlyHeldBalloons.IsEmpty())
			return false;
		
		Targetable::ApplyVisibleRange(Query, VisibleRange);
		Targetable::ApplyTargetableRange(Query, TargetableRange);

		return true;
	}
	
};