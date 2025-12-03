
class UPlayerPolevaultCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(PlayerMovementTags::ContextualMovement);
	default CapabilityTags.Add(PlayerGrappleTags::GrappleMovement);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 11;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UPlayerPolevaultComponent PolevaultComp;

	FHazeRuntimeSpline Spline;
	float DistAlongSpline;
	float Speed;
	float EnterSpeed = 1850.0;
	float FallSpeed = 1200.0;
	FVector EndPointLocLastframe;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		PolevaultComp = UPlayerPolevaultComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
        	return false;

        if (!PolevaultComp.bPolevault)
            return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if (DistAlongSpline >= Spline.Length)
			return true;

        if (MoveComp.HasAnyValidBlockingContacts())
            return true;

        if (MoveComp.IsOnWalkableGround())
            return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DistAlongSpline = 0.0;
		Speed = EnterSpeed;

        Spline = FHazeRuntimeSpline();
		Spline.AddPoint(PolevaultComp.StartLoc);
		Spline.AddPoint(PolevaultComp.MiddleLoc);
		Spline.AddPoint(PolevaultComp.EndLoc);

		Player.ApplyCameraSettings(PolevaultComp.CamSettingJump, 1, this, SubPriority = 53);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
        PolevaultComp.bPolevault = false;
        Player.SetActorVelocity(Player.ActorForwardVector * 650.0);
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PolevaultComp.DrawDebugSpline(Spline);

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{		
				DistAlongSpline += Speed * DeltaTime;

				// float AdjustedSpeed = Math::Lerp(EnterSpeed, FallSpeed);
				DistAlongSpline = Math::Clamp(DistAlongSpline, 0.0, Spline.Length);

				FVector NewLoc = Spline.GetLocationAtDistance(DistAlongSpline);

				Movement.AddDeltaFromMoveToPositionWithCustomVelocity(NewLoc, Spline.GetDirectionAtDistance(DistAlongSpline) * Speed);
				Movement.SetRotation(Spline.GetDirectionAtDistance(DistAlongSpline).Rotation());
				// Movement.OverrideStepDownAmountForThisFrame(0.0);

				if(Speed - (1200 * DeltaTime) < 1200.0)
					Speed = 1200.0;
				else
					Speed -= 1200 * DeltaTime;
			}
			MoveComp.ApplyMove(Movement);
			Player.Mesh.RequestLocomotion(n"", this);
		}

	}



};

