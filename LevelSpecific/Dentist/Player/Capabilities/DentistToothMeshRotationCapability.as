class UDentistToothMeshRotationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::Tags::CancelOnRagdoll);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UDentistToothPlayerComponent PlayerComp;
	UPlayerMovementComponent MoveComp;

	float BobTime = 0;
	float AirTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// This can be null when added from a request component in the world...
		if(PlayerComp == nullptr)
			return false;

		if(PlayerComp.HasSetMeshRotationThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return true;

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
	void PreTick(float DeltaTime)
	{
		if(PlayerComp == nullptr)
			PlayerComp = UDentistToothPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FQuat WorldRotation = Player.ActorQuat;

		if(Dentist::bApplyInputTilt)
			WorldRotation = FQuat::MakeFromZX(PlayerComp.AccTiltAmount.Value, FVector::ForwardVector) * WorldRotation;

		if(Dentist::bApplyBobRotation)
			ApplyBobRotation(WorldRotation, DeltaTime);

		PlayerComp.SetMeshWorldRotation(WorldRotation, this, Dentist::InterpVisualRotationDuration, DeltaTime);
	}

	void ApplyBobRotation(FQuat& WorldRotation, float DeltaTime)
	{
		const float BobMinSpeed = 50;
		const float BobMaxSpeed = 1000;
		const float BobAngle = Math::DegreesToRadians(10);
		const float BobFrequency = 20;

		if(MoveComp.IsInAir())
		{
			AirTime += DeltaTime;
		}
		else
		{
			AirTime = 0;
		}

		const float AirFactor = 1.0 - Math::Saturate(Math::NormalizeToRange(AirTime, 0, 0.5));
		if(AirFactor < KINDA_SMALL_NUMBER)
		{
			BobTime = 0;
		}
		else
		{
			float ForwardSpeed = Math::Max(Player.ActorVelocity.DotProduct(Player.ActorForwardVector), 0);
			const float BobSpeedAlpha = Math::Saturate(Math::NormalizeToRange(ForwardSpeed, BobMinSpeed, BobMaxSpeed));
			BobTime += BobSpeedAlpha * DeltaTime;

			float Rotation = (Math::Sin(BobTime * BobFrequency) * BobSpeedAlpha) * BobAngle;
			FQuat BobRotation = FQuat(Player.ActorForwardVector, Rotation * AirFactor);

			WorldRotation = BobRotation * WorldRotation;
		}
	}
};