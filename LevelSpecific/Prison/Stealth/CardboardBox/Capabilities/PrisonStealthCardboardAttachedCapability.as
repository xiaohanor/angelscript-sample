asset CardboardBoxTipCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	1.0 |'.                                                              |
	    |  ·                                                             |
	    |   '.                                                           |
	    |     ·                                                          |
	    |      '·                                                        |
	    |        '.                                                      |
	    |          '.                                                    |
	    |            '.                                                  |
	    |              '.                                                |
	    |                '·.                                             |
	    |                   '.                                           |
	    |                     '·..                                       |
	    |                         '·.                                    |
	    |                            ''·..                               |
	    |                                 ''··...                        |
	0.0 |                                        '''·····................|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddCurveKeyTangent(0.0, 1.0, -2.905318);
	AddLinearCurveKey(1.0, 0.0);
};

struct FPrisonStealthCardboardAttachedActivateParams
{
	AHazePlayerCharacter Player;
};

struct FPrisonStealthCardboardAttachedDeactivateParams
{
	bool bFellOff = false;
};

class UPrisonStealthCardboardAttachedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	APrisonStealthCardboardBox CardboardBox;

	// Player
	UPlayerMovementComponent MoveComp;
	UMagnetDroneJumpComponent JumpComp;
	UMagnetDroneAttractionComponent AttractionComp;
	UMagnetDroneAttachedComponent AttachedComp;

	float InitialTipAngle;
	FVector InitialTipRelativeLocation;

	FVector PreviousPlayerLocation;

	float VerticalSpeed = 0;
	float JumpHeight = 0;
	bool bIsJumping = false;
	bool bHasTipped = false;

	const float FlipDuration = 0.5;
	const FVector LagConstraint = FVector(10, 25, 1000);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CardboardBox = Cast<APrisonStealthCardboardBox>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPrisonStealthCardboardAttachedActivateParams& Params) const
	{
		if(CardboardBox.DesiredState != EPrisonStealthCardboardBoxState::Attached)
			return false;

		if(CardboardBox.Player == nullptr)
			return false;

		Params.Player = CardboardBox.Player;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPrisonStealthCardboardAttachedDeactivateParams& Params) const
	{
		if(CardboardBox.DesiredState != EPrisonStealthCardboardBoxState::Attached)
			return true;

		if(CardboardBox.CurrentState != EPrisonStealthCardboardBoxState::Attached)
			return true;

		if(!IsValid(CardboardBox.Player))
			return true;

		if(CardboardBox.Player.IsPlayerDeadOrRespawning())
		{
			Params.bFellOff = true;
			return true;
		}

		if(AttractionComp.IsAttracting())
		{
			Params.bFellOff = true;
			return true;
		}

		if(AttachedComp.IsAttached())
		{
			Params.bFellOff = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPrisonStealthCardboardAttachedActivateParams Params)
	{
		CardboardBox.ApplyState(EPrisonStealthCardboardBoxState::Attached);

		CardboardBox.Player = Params.Player;

		InitialTipAngle = CardboardBox.TipRoot.RelativeRotation.Pitch;
		InitialTipRelativeLocation = CardboardBox.TipRoot.RelativeLocation;

		PreviousPlayerLocation = CardboardBox.Player.ActorLocation;

		MoveComp = UPlayerMovementComponent::Get(CardboardBox.Player);
		JumpComp = UMagnetDroneJumpComponent::Get(CardboardBox.Player);
		AttractionComp = UMagnetDroneAttractionComponent::Get(CardboardBox.Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(CardboardBox.Player);

		UPrisonStealthCardboardBoxEventHandler::Trigger_OnCardboardBoxEnter(CardboardBox);
		UPrisonStealthCardboardBoxPlayerComponent::Get(CardboardBox.Player).OnCardboardBoxAttached(CardboardBox);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPrisonStealthCardboardAttachedDeactivateParams Params)
	{
		if(Params.bFellOff)
		{
			FVector ImpulseDirection = Math::VRandCone(FVector::UpVector, 1, 1);
			if(CardboardBox.Player != nullptr)
			{
				if(CardboardBox.Player.ActorHorizontalVelocity.Size() > 1)
				{
					ImpulseDirection += MoveComp.PreviousHorizontalVelocity.GetSafeNormal();
				}
			}

			CardboardBox.StartSimulating(ImpulseDirection * 100);
		}

		UPrisonStealthCardboardBoxEventHandler::Trigger_OnCardboardBoxLeave(CardboardBox);
		UPrisonStealthCardboardBoxPlayerComponent::Get(CardboardBox.Player).OnCardboardBoxDetached();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < FlipDuration)
		{
			const float TipAlpha = ActiveDuration / FlipDuration;
			float TipAngle = CardboardBoxTipCurve.GetFloatValue(TipAlpha) * InitialTipAngle;
			CardboardBox.TipRoot.SetRelativeRotation(FRotator(TipAngle, 0, 0));
		}
		else
		{
			bHasTipped = true;
		}

		CardboardBox.TipRoot.SetRelativeLocation(InitialTipRelativeLocation);

		FVector BoxLocation = GetConstrainedHorizontalLocation();
		BoxLocation.Z = CalculateHeightLocation(DeltaTime);

		FQuat BoxRotation = CardboardBox.ActorQuat;

		if(bHasTipped)
		{
			if(CardboardBox.Player.ActorHorizontalVelocity.Size() > 10)
			{
				FQuat TargetRotation = FQuat::MakeFromZY(FVector::UpVector, CardboardBox.Player.ActorHorizontalVelocity.VectorPlaneProject(FVector::UpVector));
				const float RotateSpeed = Math::GetPercentageBetweenClamped(0, 1000, CardboardBox.Player.ActorHorizontalVelocity.Size()) * 2;
				BoxRotation = Math::QInterpTo(BoxRotation, TargetRotation, DeltaTime, RotateSpeed);
			}
		}

		CardboardBox.SetActorLocationAndRotation(BoxLocation, BoxRotation);

		PreviousPlayerLocation = CardboardBox.Player.ActorLocation;
	}

	FVector GetConstrainedHorizontalLocation() const
	{
		FTransform ConstraintTransform = FTransform(FQuat::MakeFromZX(FVector::UpVector, CardboardBox.ActorForwardVector), CardboardBox.Player.MeshOffsetComponent.WorldLocation);
		FVector HorizontalOffsetFromPlayer = ConstraintTransform.InverseTransformPositionNoScale(CardboardBox.ActorLocation);

		// Horizontal Constraint
		HorizontalOffsetFromPlayer = FVector(
			Math::Clamp(HorizontalOffsetFromPlayer.X, -LagConstraint.X, LagConstraint.X),
			Math::Clamp(HorizontalOffsetFromPlayer.Y, -LagConstraint.Y, LagConstraint.Y),
			0
		);

		return ConstraintTransform.TransformPositionNoScale(HorizontalOffsetFromPlayer);
	}

	float CalculateHeightLocation(float DeltaTime)
	{
		float VerticalDelta = 0;
		if(JumpComp.StartedJumpingThisOrLastFrame() && CardboardBox.ActorLocation.Z < CardboardBox.Player.ActorLocation.Z)
		{
			VerticalSpeed = 1500;
			JumpHeight = CardboardBox.ActorLocation.Z;
			bIsJumping = true;
		}
		else
		{
			Acceleration::ApplyAccelerationToSpeed(VerticalSpeed, -3000, DeltaTime, VerticalDelta);
		}

		if(bIsJumping)
		{
			float VerticalOffset = CardboardBox.ActorLocation.Z - JumpHeight;
			VerticalDelta += VerticalSpeed * DeltaTime;
			VerticalOffset += VerticalDelta;

			if(JumpHeight + VerticalOffset < CardboardBox.Player.MeshOffsetComponent.WorldLocation.Z)
			{
				// We are below the player, stop jumping
				bIsJumping = false;
				return CardboardBox.Player.MeshOffsetComponent.WorldLocation.Z;
			}

			return JumpHeight + VerticalOffset;
		}
		else
		{
			return CardboardBox.Player.MeshOffsetComponent.WorldLocation.Z;
		}
	}
};