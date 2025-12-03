struct FMagnetDroneSurfaceJumpActivatedParams
{
	FVector JumpDirection;
};

class UMagnetDroneSurfaceJumpCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default DebugCategory = Drone::DebugCategory;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(MagnetDroneTags::MagnetDroneJump);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttraction);
	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileInMagnetDroneBounce);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 80;
	default TickGroupSubPlacement = 90;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttachedComponent AttachedComp;
	UMagnetDroneJumpComponent JumpComp;

	UHazeMovementComponent MoveComp;

	private float JumpGraceTimer = BIG_NUMBER;
	private float LastAttachedTime;
	private FMagnetDroneAttachedData LastAttachment;
	private FVector LastGroundNormal;
	private bool bHasWaitedForDetach;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
		JumpComp = UMagnetDroneJumpComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FMagnetDroneSurfaceJumpActivatedParams& Params) const
	{
		const bool bInputting = JumpComp.WasJumpInputStartedDuringTime(DroneComp.MovementSettings.JumpInputBufferTime);
		const bool bJumpFromSocket = AttachedComp.ForceDetachedFromSocketWithJumpThisOrLastFrame();

		if(!bInputting && !bJumpFromSocket)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

  		if(!IsInJumpGracePeriod())
			return false;

		if(!DroneComp.Settings.bAllowJumpingWhileMagneticallyAttached)
			return false;

		if(!LastAttachment.IsValid())
			return false;

		if(!LastAttachment.IsSurface())
			return false;

		if(Time::GetGameTimeSince(LastAttachedTime) > DroneComp.MovementSettings.JumpGraceTime)
			return false;

		if(JumpComp.IsJumping())
			return false;

		if(AttachedComp.AttachedThisOrLastFrame())
			return false;

		if(!LastGroundNormal.IsNearlyZero())
			Params.JumpDirection = LastGroundNormal;
		else
			Params.JumpDirection = Player.ActorUpVector;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnWalkableGround())
			return true;

		if(AttachedComp.IsAttached())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FMagnetDroneSurfaceJumpActivatedParams Params)
	{
		JumpComp.ConsumeJumpInput();

		// Make sure to detach
		if(AttachedComp.IsAttached())
			AttachedComp.Detach(n"SurfaceJump");

		JumpComp.ApplyIsJumping(this, Params.JumpDirection);
		JumpComp.AddJumpImpulse(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.ClearIsJumping(this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("JumpGraceTimer", JumpGraceTimer);
		TemporalLog.Value("LastAttachedTime", LastAttachedTime);
		TemporalLog.Value("LastGroundNormal", LastGroundNormal);
		TemporalLog.Value("bHasWaitedForDetach", bHasWaitedForDetach);
		LastAttachment.LogToTemporalLog(TemporalLog, "Last Attachment");
	}
#endif

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(AttachedComp.IsAttached())
		{
			LastAttachedTime = Time::GameTimeSeconds;
			LastAttachment = AttachedComp.AttachedData;

			if(MoveComp.HasGroundContact())
				LastGroundNormal = MoveComp.GroundContact.ImpactNormal;

			JumpGraceTimer = 0.0;
			bHasWaitedForDetach = false;
		}
		else
		{
			if (MoveComp.IsOnWalkableGround())
			{
				JumpGraceTimer = 0.0;
				LastGroundNormal = MoveComp.GroundContact.ImpactNormal;

				if(bHasWaitedForDetach)
				{
					// We need to wait one frame before clearing to allow the WorldUp and grounding state to reset
					LastAttachedTime = -BIG_NUMBER;
 					LastAttachment = FMagnetDroneAttachedData();
				}
				else
				{
					bHasWaitedForDetach = true;
				}
			}
			else
			{
				JumpGraceTimer += DeltaTime;
			}
		}
	}

	bool IsInJumpGracePeriod() const
	{
		return JumpGraceTimer <= DroneComp.MovementSettings.JumpGraceTime;
	}
};