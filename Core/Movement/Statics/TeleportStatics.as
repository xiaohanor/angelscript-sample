/**
 * Teleporting an actor will reset any movement component and trigger a network transition with the instigator
 */
UFUNCTION()
mixin void TeleportActor(AHazeActor Actor, FVector Location, FRotator Rotation, FInstigator Instigator, bool bIncludeCamera = true)
{
	UHazeCrumbSyncedActorPositionComponent NetworkMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Actor);
	if (NetworkMotionComp != nullptr)
		NetworkMotionComp.TransitionSync(Instigator);

	Actor.SetActorLocationAndRotation(Location, Rotation, bTeleport = true);
	Actor.ResetMovement();

	// Clear any remaining vertical movement lerp
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if (IsValid(MoveComp))
		MoveComp.ClearVerticalLerp();

	if (bIncludeCamera)
	{
		auto CamUser = UCameraUserComponent::Get(Actor);
		if(CamUser != nullptr)
			CamUser.OnTeleportOwner();
	}
		
	auto TeleportComp = UTeleportResponseComponent::GetOrCreate(Actor);
	if (TeleportComp != nullptr)
	{
		TeleportComp.OnTeleported.Broadcast();
		TeleportComp.LastTeleportFrame = GFrameNumber;
	}
}

/**
 * Teleporting a character will reset the movement component and trigger a network transition with the instigator
 */
UFUNCTION()
mixin void SmoothTeleportActor(AHazeActor Actor, FVector Location, FRotator Rotation, FInstigator Instigator, float Time = 0.2)
{
	if (Time <= 0.0)
	{
		Actor.TeleportActor(Location, Rotation, Instigator);
		return;
	}

	UHazeCrumbSyncedActorPositionComponent NetworkMotionComp = UHazeCrumbSyncedActorPositionComponent::Get(Actor);
	if (NetworkMotionComp != nullptr)
		NetworkMotionComp.TransitionSync(Instigator);	

	auto Player = Cast<AHazePlayerCharacter>(Actor);
	auto Character = Cast<AHazeCharacter>(Actor);
	if (Player != nullptr)
	{
		Player.GetRootOffsetComponent().FreezeTransformAndLerpBackToParent(n"MoveToSmoothTeleport", Time);
	}
	else if (Character != nullptr)
	{
		auto OffsetComp = Character.MeshOffsetComponent;
		if (OffsetComp != nullptr)
			OffsetComp.FreezeTransformAndLerpBackToParent(n"MoveToSmoothTeleport", Time);
	}
	else
	{
		auto OffsetComp = UHazeOffsetComponent::Get(Actor);
		if (OffsetComp != nullptr)
			OffsetComp.FreezeTransformAndLerpBackToParent(n"MoveToSmoothTeleport", Time);
		else
			devError(f"Attempting to Smooth Teleport an Actor ({Actor.Name}) without an Offset Component");
	}

	Actor.SetActorLocationAndRotation(Location, Rotation);

	// Clear any remaining vertical movement lerp
	auto MoveComp = UHazeMovementComponent::Get(Actor);
	if (IsValid(MoveComp))
		MoveComp.ClearVerticalLerp();

	auto TeleportComp = UTeleportResponseComponent::GetOrCreate(Actor);
	if (TeleportComp != nullptr)
	{
		TeleportComp.OnTeleported.Broadcast();
		TeleportComp.LastTeleportFrame = GFrameNumber;
	}
}

// Access from C++
class UActorTeleportHelper : UHazeActorTeleportHelper
{
	UFUNCTION(BlueprintOverride)
	void TeleportActor(AHazeActor InActor, FVector InLocation, FRotator InRotation, FInstigator InInstigator, bool bIncludeCamera = true)
	{
		InActor.TeleportActor(InLocation, InRotation, InInstigator, bIncludeCamera);
	}

	UFUNCTION(BlueprintOverride)
	void SmoothTeleportActor(AHazeActor InActor, FVector InLocation, FRotator InRotation, FInstigator InInstigator, float InTime)
	{
		InActor.SmoothTeleportActor(InLocation, InRotation, InInstigator, InTime);
	}
}

// Response component to detect when actors are teleported
event void FOnActorTeleported();

class UTeleportResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnActorTeleported OnTeleported;
	uint LastTeleportFrame = 0;

	bool HasTeleportedSinceLastFrame()
	{
		return LastTeleportFrame >= GFrameNumber - 1;
	}

	bool HasTeleportedWithinFrameWindow(uint FrameWindow = 1)
	{
		return LastTeleportFrame >= GFrameNumber - FrameWindow;
	}
};