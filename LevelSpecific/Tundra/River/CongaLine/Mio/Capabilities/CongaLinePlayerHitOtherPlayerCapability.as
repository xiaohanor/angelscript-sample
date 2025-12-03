
class UCongaLinePlayerHitOtherPlayerCapability : UHazePlayerCapability
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
	float LastHitPlayerTime = 0;

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
		if(CongaLine::IgnoreCollisions.IsEnabled())
			return false;

		float Dist = Game::GetOtherPlayer(Player.Player).ActorLocation.Distance(Player.ActorLocation);
		if(Dist > CongaLine::OtherPlayerCollisionRadius)
				return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasWallContact())
			return true;

		if(CongaLine::IgnoreCollisions.IsEnabled())
			return true;

		if(Time::GetGameTimeSince(LastHitPlayerTime) < CongaLine::HitWallDuration)
			return false;

		if(Owner.ActorQuat.AngularDistance(GetTargetRotation()) > 0.01)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		RedirectFromPlayer();
		CongaComp.PlayWallHitRumble();
		Player.BlockCapabilities(CongaLine::Tags::CongaLineStrikePose, this);
		Player.ApplySettings(CongaLineHitWallPlayerSettings, this);

		CongaComp.bStunned = true;
		LastHitPlayerTime = Time::GameTimeSeconds;
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

	void RedirectFromPlayer()
	{
		AHazePlayerCharacter OtherPlayer = Game::GetOtherPlayer(Player.Player);

		FVector DirAwayFromPlayer = (Player.ActorLocation - OtherPlayer.ActorLocation).GetSafeNormal();
		ReflectToDirection = VelocityLastFrame.GetReflectionVector(DirAwayFromPlayer);
		ReflectToDirection = ReflectToDirection.VectorPlaneProject(FVector::UpVector).GetSafeNormal();

		if(!Network::IsGameNetworked())
			CongaComp.DisperseBothPlayersMonkeys();
		else
			CongaComp.DisperseAllDancers();
	}

	FQuat GetTargetRotation() const
	{
		return FQuat::MakeFromX(ReflectToDirection);
	}
};