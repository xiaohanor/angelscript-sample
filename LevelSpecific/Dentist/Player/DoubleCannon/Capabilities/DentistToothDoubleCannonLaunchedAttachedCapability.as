struct FDentistToothDoubleCannonLaunchedAttachedDeactivateParams
{
	bool bDetach = false;
}

class UDentistToothDoubleCannonLaunchedAttachedCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default BlockExclusionTags.Add(Dentist::DoubleCannon::DentistDoubleCannonBlockExclusionTag);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 51;

	UDentistToothPlayerComponent PlayerComp;
	UDentistToothDoubleCannonComponent CannonComp;

	UPlayerMovementComponent MoveComp;
	USimpleMovementData MoveData;

	FVector OffsetFromLaunchedRoot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		CannonComp = UDentistToothDoubleCannonComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if(!CannonComp.IsLaunched())
			return false;

		if(CannonComp.ShouldBeDetached())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDentistToothDoubleCannonLaunchedAttachedDeactivateParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		if(!CannonComp.IsLaunched())
			return true;

		if(MoveComp.HasAnyValidBlockingImpacts())
			return true;

		if(CannonComp.ShouldBeDetached())
		{
			Params.bDetach = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UDentistToothDoubleCannonEventHandler::Trigger_OnLaunched(Player);

		auto AttachmentComp = CannonComp.GetCannon().LaunchedRoot.GetAttachmentForPlayer(Player.Player);
		FTransform LaunchTransform = CannonComp.GetCurrentLaunchTransform();
		OffsetFromLaunchedRoot = Player.ActorLocation - LaunchTransform.Location;

		MoveComp.AddMovementIgnoresActor(this, CannonComp.GetCannon());
		MoveComp.FollowComponentMovement(AttachmentComp, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Interaction);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDentistToothDoubleCannonLaunchedAttachedDeactivateParams Params)
	{
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.RemoveMovementIgnoresActor(this);

		if(Params.bDetach)
		{

		}
		else
		{
			// We got interrupted by something!
			CannonComp.Reset();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(MoveData))
		{
			OffsetFromLaunchedRoot = Math::VInterpTo(OffsetFromLaunchedRoot, FVector::ZeroVector, DeltaTime, 10);
			FTransform LaunchTransform = CannonComp.GetCurrentLaunchTransform();

			FVector Location = LaunchTransform.Location + OffsetFromLaunchedRoot;
			FQuat Rotation = FQuat::MakeFromZX(FVector::UpVector, MoveComp.Velocity);

			if (HasControl())
			{
				MoveData.AddDeltaFromMoveTo(Location);
				MoveData.SetRotation(Rotation);
			}
			else
			{
				auto CrumbSyncedPosition = MoveComp.GetCrumbSyncedPosition();
				MoveData.ApplyManualSyncedLocationAndRotation(Location, CrumbSyncedPosition.WorldVelocity, Rotation.Rotator());
			}

			MoveComp.ApplyMoveAndRequestLocomotion(MoveData, Dentist::Feature);
		}

		TickMeshRotation(DeltaTime);
	}

	UFUNCTION()
	private bool IdleUntilCondition() const
	{
		if(ActiveDuration < 5)
			return false;

		return true;
	}

	UFUNCTION()
	private void AfterTimer()
	{
		Print("Wohoo!");
	}

	void TickMeshRotation(float DeltaTime)
	{
		if(PlayerComp.HasSetMeshRotationThisFrame())
			return;

		FTransform LaunchTransform = CannonComp.GetCurrentLaunchTransform();

		FQuat CurrentRotation = PlayerComp.GetMeshWorldRotation();
		FQuat NewRotation = Math::QInterpConstantTo(CurrentRotation, LaunchTransform.Rotation, DeltaTime, 10);

		if(Dentist::DoubleCannon::bApplyRotation)
			PlayerComp.SetMeshWorldRotation(NewRotation, this, -1, DeltaTime);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Transform("Player Transform", Player.ActorTransform);
		TemporalLog.Transform("Mesh Transform", PlayerComp.GetToothActor().ActorTransform);
		TemporalLog.Transform("Launch Transform", CannonComp.GetCurrentLaunchTransform());
	}
#endif
};