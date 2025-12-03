class USummitAirCurrentActivatorInteractionCapability : UInteractionCapability
{
	ASummitAirCurrentActivator AirCurrentActivator;

	UPlayerTailTeenDragonComponent DragonComp;
	//ATeenDragon TeenDragon;

	float ActivationDistance = 0.0;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FInteractionCapabilityParams Params)
	{
		Super::OnActivated(Params);
		
		AirCurrentActivator = Cast<ASummitAirCurrentActivator>(Params.Interaction.Owner);
		check(AirCurrentActivator != nullptr);

		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		//TeenDragon = DragonComp.TeenDragon;
		ActivationDistance = AirCurrentActivator.ActivationDistance;

		AirCurrentActivator.EnterInteraction(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		AirCurrentActivator.ExitInteraction();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform AttachmentBone = DragonComp.DragonMesh.GetSocketTransform(n"Jaw");
		float DistSqrToActivator = AirCurrentActivator.Root.WorldLocation.DistSquared(AttachmentBone.Location);
		float SqrDistThreshold = Math::Square(ActivationDistance);
		if(DistSqrToActivator > SqrDistThreshold)
		{
			AirCurrentActivator.ActivateWindCurrent();
			LeaveInteraction();
		}
	}
}