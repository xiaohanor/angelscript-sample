class UDentistBossToolDenturesRidingRotationCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;
	UCameraUserComponent CameraUserComp;
	UDentistToothPlayerComponent ToothComp;
	UPlayerMovementComponent MoveComp;

	UDentistBossSettings Settings;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
		Dentist = TListedActors<ADentistBoss>().GetSingle();

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Dentures.bDestroyed)
			return false;

		if(!Dentures.ControllingPlayer.IsSet())
			return false;

		if(Dentures.IsBitingHand())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Dentures.bDestroyed)
			return true;

		if(!Dentures.ControllingPlayer.IsSet())
			return true;

		if(Dentures.IsBitingHand())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = Dentures.ControllingPlayer.Value;
		CameraUserComp = UCameraUserComponent::Get(Player);
		ToothComp = UDentistToothPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearMovementInput(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MovementInput = FVector::ZeroVector;
		FRotator NewRotation = FRotator::ZeroRotator;
		if(HasControl())
		{
			FVector2D LeftStickRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			if(LeftStickRaw.IsNearlyZero(0.2))
				return;

			MovementInput = FVector(LeftStickRaw.X, LeftStickRaw.Y, 0);
			FRotator ControlRotation = CameraUserComp.ControlRotation;
			ControlRotation.Pitch = 0.0;
			ControlRotation.Roll = 0.0;
			MovementInput = ControlRotation.RotateVector(MovementInput);
			Player.ApplyMovementInput(MovementInput, this);

			FRotator TargetRotation = FRotator::MakeFromXZ(MovementInput, FVector::UpVector);

			NewRotation = Math::RInterpConstantTo(Dentures.ActorRotation, TargetRotation, DeltaTime, Settings.DenturesRidingRotationSpeed);
			
		}
		else
		{
			NewRotation = Dentures.CrumbActorPositionComp.GetPosition().WorldRotation;
		}
		
		ToothComp.SetMeshWorldRotation(NewRotation.Quaternion(), this);
		Dentures.ActorRotation = NewRotation;
	}
};