enum EDentistToothWaterDeathType
{
	Landscape,
	Impact,
};

struct FDentistToothWaterDeathActivateParams
{
	EDentistToothWaterDeathType Type;
	UDentistToothWaterDeathImpactComponent WaterDeathImpactComp;
	FVector ImpactLocation;
	FVector ImpactNormal;
};

class UDentistToothWaterDeathCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default TickGroup = EHazeTickGroup::BeforeMovement;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothWaterDeathComponent WaterDeathComp;

	UPlayerMovementComponent MoveComp;
	UTeleportingMovementData MoveData;

	FVector AngularVelocity;
	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		WaterDeathComp = UDentistToothWaterDeathComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistToothWaterDeathActivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(Player.IsPlayerDead())
			return false;

		for(const auto& Impact : MoveComp.AllImpacts)
		{
			auto WaterDeathImpactComp = UDentistToothWaterDeathImpactComponent::Get(Impact.Actor);
			if(WaterDeathImpactComp != nullptr)
			{
				// Death from water impact comp!
				Params.Type = EDentistToothWaterDeathType::Impact;
				Params.WaterDeathImpactComp = WaterDeathImpactComp;
				Params.ImpactLocation = Impact.ImpactPoint;
				Params.ImpactNormal = Impact.Normal;
				return true;
			}
		}

		// We are above the water
		if(Owner.ActorLocation.Z > WaterDeathComp.GetChocolateWaterHeight(Owner.ActorLocation))
			return false;

		Params.Type = EDentistToothWaterDeathType::Landscape;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!Player.IsPlayerDead())
			return true;

		if(Player.GetFadeOutPercentage() > 1.0 - KINDA_SMALL_NUMBER)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistToothWaterDeathActivateParams Params)
	{
		switch(Params.Type)
		{
			case EDentistToothWaterDeathType::Landscape:
			{
				WaterDeathComp.DeathLocation = WaterDeathComp.GetChocolateWaterSurfaceLocation(Owner.ActorLocation);
				WaterDeathComp.DeathNormal = WaterDeathComp.GetChocolateWaterSurfaceNormal(Owner.ActorLocation);
				break;
			}

			case EDentistToothWaterDeathType::Impact:
			{
				MoveComp.AddMovementIgnoresActor(this, Params.WaterDeathImpactComp.Owner);
				WaterDeathComp.DeathLocation = Params.ImpactLocation;
				WaterDeathComp.DeathNormal = Params.ImpactNormal;
				break;
			}
		}
		
		AngularVelocity = PlayerComp.GetMeshAngularVelocity();

		FVector PreviousVerticalVelocity = MoveComp.PreviousVerticalVelocity;
		PreviousVerticalVelocity *= 0.5;
		FVector PreviousVelocity = MoveComp.PreviousHorizontalVelocity + PreviousVerticalVelocity;
		Player.SetActorVelocity(PreviousVelocity);
		
		StartLocation = Player.ActorLocation;

		FPlayerDeathDamageParams DeathParams;
		Player.KillPlayer(DeathParams, WaterDeathComp.DeathEffect);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComp.RemoveMovementIgnoresActor(this);

		if(Dentist::WaterDeath::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(Player.ActorQuat, this);
		
		UCameraSettings::GetSettings(Player).WorldPivotOffset.Clear(this, 0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData, FVector::UpVector))
			return;

		if(HasControl())
		{
			FVector VerticalVelocity = MoveComp.VerticalVelocity;
			if(VerticalVelocity.DotProduct(FVector::UpVector) > 0)
				VerticalVelocity = VerticalVelocity.VectorPlaneProject(FVector::UpVector);

			VerticalVelocity = Math::VInterpTo(VerticalVelocity, FVector::DownVector * Dentist::WaterDeath::SinkingTargetSpeed, DeltaTime, Dentist::WaterDeath::SinkingVerticalInterpSpeed);

			FVector HorizontalVelocity = MoveComp.HorizontalVelocity;
			HorizontalVelocity = Math::VInterpTo(HorizontalVelocity, FVector::ZeroVector, DeltaTime, Dentist::WaterDeath::SinkingHorizontalInterpSpeed);

			FVector Velocity = HorizontalVelocity + VerticalVelocity;

			MoveData.AddVelocity(Velocity);
			MoveData.SetRotation(FQuat::MakeFromZX(FVector::UpVector, Owner.ActorForwardVector));
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
		}

		MoveComp.ApplyMoveAndRequestLocomotion(MoveData, Dentist::Feature);

		AngularVelocity = Math::VInterpTo(AngularVelocity, FVector::ZeroVector, DeltaTime, Dentist::WaterDeath::SinkingAngularVelocityInterpSpeed);
		FQuat DeltaRotation = FQuat(AngularVelocity.GetSafeNormal(), AngularVelocity.Size() * DeltaTime);
		FQuat NewRotation = DeltaRotation * PlayerComp.GetMeshWorldRotation();

		NewRotation = Math::QInterpConstantTo(NewRotation, FQuat::MakeFromZ(FVector::DownVector), DeltaTime, Dentist::WaterDeath::SinkingRotationInterpSpeed);
		
		if(Dentist::WaterDeath::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(NewRotation, this, 0, DeltaTime);

		FVector OffsetFromStart = Player.ActorLocation - StartLocation;

		UCameraSettings::GetSettings(Player).WorldPivotOffset.Apply(-OffsetFromStart, this);
	}
};