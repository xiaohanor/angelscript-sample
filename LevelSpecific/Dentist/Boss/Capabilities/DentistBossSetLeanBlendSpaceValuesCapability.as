class UDentistBossSetLeanBlendSpaceValuesCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	ADentistBoss Dentist;
	UDentistBossTargetComponent TargetComp;

	FHazeAcceleratedVector2D AccBlendSpaceValues;

	const float BlendTime = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentist = Cast<ADentistBoss>(Owner);
		TargetComp = UDentistBossTargetComponent::Get(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D TargetBlendSpaceValues;

		auto Target = TargetComp.Target.Get();
		if(Target != nullptr
		&& Dentist.UseLeanBlendSpace.Get())
		{
			auto DeltaToTarget = Target.ActorLocation - Dentist.Cake.ActorLocation;
			DeltaToTarget /= Dentist.Cake.OuterRadius;

			float ForwardsAmount = Dentist.SkelMesh.ForwardVector.DotProduct(DeltaToTarget);
			ForwardsAmount = Math::Clamp(ForwardsAmount, -1.0, 1.0);
			ForwardsAmount += 1.0;
			ForwardsAmount *= 0.5;
			float RightAmount = Dentist.SkelMesh.RightVector.DotProduct(DeltaToTarget);
			RightAmount = Math::Clamp(RightAmount, -1.0, 1.0);

			TargetBlendSpaceValues = FVector2D(RightAmount, ForwardsAmount);
		}
		else
			TargetBlendSpaceValues = FVector2D::ZeroVector;

		AccBlendSpaceValues.AccelerateTo(TargetBlendSpaceValues, BlendTime, DeltaTime);
		Dentist.LeanBlendSpaceValues.SetDefaultValue(AccBlendSpaceValues.Value);

		TEMPORAL_LOG(Dentist, "IK")
			.Value("Lean Blend Space Values", TargetBlendSpaceValues)
		;
	}


};