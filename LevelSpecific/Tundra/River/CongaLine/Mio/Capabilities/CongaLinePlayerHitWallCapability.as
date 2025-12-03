asset CongaLineHitWallPlayerSettings of UCongaLinePlayerSettings
{
	MoveSpeed = 600;
};

/**
 * Check if we hit a wall, and if we did, play an animation and reflect off of it.
 */
class UCongaLinePlayerHitWallCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CongaLine::Tags::CongaLine);
	default CapabilityTags.Add(CongaLine::Tags::CongaLineMovement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	UCongaLinePlayerComponent CongaComp;
	
	UPlayerMovementComponent MoveComp;
	USteppingMovementData MoveData;

	FVector VelocityThisFrame;
	FVector VelocityLastFrame;

	FVector ReflectToDirection;
	float LastHitWallTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CongaComp = UCongaLinePlayerComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MoveComp.HasWallContact())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Time::GetGameTimeSince(LastHitWallTime) < CongaLine::HitWallDuration)
			return false;

		if(Owner.ActorQuat.AngularDistance(GetTargetRotation()) > 0.01)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RedirectFromWall();
		CongaComp.HitWallAtCurrentLocation();
		CongaComp.PlayWallHitRumble();
		Player.BlockCapabilities(CongaLine::Tags::CongaLineStrikePose, this);
		Player.ApplySettings(CongaLineHitWallPlayerSettings, this);

		CongaComp.bStunned = true;
		LastHitWallTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CongaLine::Tags::CongaLineStrikePose, this);
		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		/**
		 * We do this stupid hack since the velocity will have been redirected already when we get the wall impact.
		 * This is where the ~ Realm of Resolvers ~ starts to show it's ugly head. If you want to try adding some
		 * custom movement resolver functionality, let me know!
		 */
		VelocityLastFrame = VelocityThisFrame;
		VelocityThisFrame = MoveComp.Velocity;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData))
			return;

		if (HasControl())
		{
			if(MoveComp.HasWallContact() && Time::GetGameTimeSince(LastHitWallTime) > 0.5)
			{
				// Handle hitting another wall while active
				RedirectFromWall();
			}

			MoveData.AddOwnerVerticalVelocity();
			MoveData.AddGravityAcceleration();

			FQuat TargetRotation = GetTargetRotation();
			MoveData.InterpRotationTo(TargetRotation, 5, true);

			float Speed = (CongaComp.Settings.MoveSpeed + CongaComp.GetSpeedBonus()) * 0.5;
			if(Speed < CongaComp.Settings.MinimumWallHitMoveSpeed)
				Speed = CongaComp.Settings.MinimumWallHitMoveSpeed;
			
			const FVector Velocity = ReflectToDirection * Speed;
			MoveData.AddVelocity(Velocity);
		}
		else
		{
			MoveData.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMoveAndRequestLocomotion(MoveData, n"CongaMovement");
	}

	void RedirectFromWall()
	{
		FVector WallNormal = MoveComp.WallContact.Normal;
		ReflectToDirection = VelocityLastFrame.GetReflectionVector(WallNormal);
		ReflectToDirection = ReflectToDirection.VectorPlaneProject(FVector::UpVector).GetSafeNormal();

		//FCongaLinePLayerOnHitWallEventData EventData;
		// EventData.DispersedDancers = CongaComp.GetDancers();
		//UCongaLinePlayerEventHandler::Trigger_OnHitWall(Player, EventData);

		// CongaComp.DisperseAllDancers();

		//LastHitWallTime = Time::GameTimeSeconds;
	}

	FQuat GetTargetRotation() const
	{
		return FQuat::MakeFromX(ReflectToDirection);
	}
};