

/**
 * Have the player perform a moveto with specified settings.
 * Different types of movetos and teleports are available here, see FMoveToParams.
 */
UFUNCTION(Category = "Move To")
mixin void MovePlayerTo(AHazePlayerCharacter Player, FMoveToParams Params, FMoveToDestination Destination, FOnMoveToEnded OnMoveToEnded)
{
	MoveTo::MoveActorTo(Player, Params, Destination, OnMoveToEnded);
}

namespace MoveTo
{

// Any animate to shorter than this range is applied instantly as a smooth teleport instead
const float ANIMATE_TO_INSTANT_RANGE = 100.0;
// Any jump to shorter than this range is applied instantly as a smooth teleport instead
const float JUMP_TO_INSTANT_RANGE = 0.0;

/**
 * Performs a generic moveto with this actor.
 * Different types of movetos and teleports are available here, see FMoveToParams.
 */
UFUNCTION(Category = "Move To")
void MoveActorTo(AHazeActor Actor, FMoveToParams Params, FMoveToDestination Destination, FOnMoveToEnded OnMoveToEnded)
{
	if (Params.Type == EMoveToType::NoMovement)
	{
		// No movement is treated specially and executes immediately
		OnMoveToEnded.ExecuteIfBound(Actor);
	}
	else
	{
		if (Actor.HasControl())
			UMoveToComponent::GetOrCreate(Actor).MoveTo(Params, Destination, OnMoveToEnded);
	}
}

/**
 * Instantly applies a moveto that can be instant.
 * Not all moveto types can be instant, 
 *
 * OBS!
 * This does not do networking, so only call this if you've already implemented networking yourself.
 * OBS!
 * 
 */
void ApplyMoveToInstantly(AHazeActor Actor, FMoveToParams Params, FMoveToDestination Destination)
{
	switch (Params.Type)
	{
		case EMoveToType::SmoothTeleport:
		case EMoveToType::AnimateTo:
		case EMoveToType::JumpTo:
			ApplySmoothTeleport(Actor, Params, Destination);
		break;
		case EMoveToType::SnapTeleport:
		{
			FTransform Transform = Destination.CalculateDestination(Actor.ActorTransform, Params);
			Actor.TeleportActor(Transform.Location, Transform.Rotator(), n"MoveToTeleport");
		}
		break;
		case EMoveToType::NoMovement:
			// Don't need to do anything at all
		break;
		default:
			devError("Cannot apply move to with type "+Params.Type+" as instant!");
		break;
	}
}

bool CanApplyMoveToInstantly(AHazeActor Actor, FMoveToParams Params, FMoveToDestination Destination)
{
	switch (Params.Type)
	{
		case EMoveToType::SmoothTeleport:
		case EMoveToType::SnapTeleport:
		case EMoveToType::NoMovement:
			return true;
		case EMoveToType::AnimateTo:
		{
			FTransform Transform = Destination.CalculateDestination(Actor.ActorTransform, Params);
			float Distance = Actor.ActorLocation.Distance(Transform.Location);
			return Distance <= ANIMATE_TO_INSTANT_RANGE;
		}
		case EMoveToType::JumpTo:
		{
			FTransform Transform = Destination.CalculateDestination(Actor.ActorTransform, Params);
			float Distance = Actor.ActorLocation.Distance(Transform.Location);
			return Distance <= JUMP_TO_INSTANT_RANGE;
		}
	}
}

};