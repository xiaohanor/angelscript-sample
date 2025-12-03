class UAdultDragonAcidSoftLockComponent : UTargetableComponent
{
	UPROPERTY(EditAnywhere, Category = "PointOfInterest")
	float Duration = 2;

	UPROPERTY(EditAnywhere, Category = "PointOfInterest")
	float BlendTime = 2;

	UPROPERTY(EditAnywhere, Category = "PointOfInterest")
	bool bClearOnInput = true;

	UCameraPointOfInterest PointOfInterest;
	UAcidResponseComponent AcidResponseComp;

	default TargetableCategory = n"PrimaryLevelAbility";
	default UsableByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(EditAnywhere)
	float TargetableVisibleRange = 5000;

	UPROPERTY(EditAnywhere)
	float TargetableRange = 5000;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		Targetable::ApplyVisibleRange(Query, TargetableVisibleRange );
		Targetable::ApplyTargetableRange(Query, TargetableRange);

		Targetable::ScoreCameraTargetingInteraction(Query);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		AcidResponseComp = UAcidResponseComponent::Get(Owner);

		if(AcidResponseComp == nullptr)
			devError(f"There is no AcidResponseComponent on {Owner} for {this} to hook up to");

		PointOfInterest = Game::Mio.CreatePointOfInterest();

		// AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnAcidHit(FAcidHit Hit)
	{
		PointOfInterest.FocusTarget.SetFocusToComponent(this);
		if(bClearOnInput)
			PointOfInterest.Settings.ClearOnInput = CameraPOIDefaultClearOnInput;
		PointOfInterest.Settings.Duration = Duration;
		PointOfInterest.Settings.TurnScaling = FRotator(1,1,0);
		
		FVector LocalLocation = Owner.ActorTransform.InverseTransformPosition(Hit.ImpactLocation);
		PointOfInterest.FocusTarget.LocalOffset = LocalLocation;
		PointOfInterest.Apply(this, BlendTime, EHazeCameraPriority::High);
	}
}