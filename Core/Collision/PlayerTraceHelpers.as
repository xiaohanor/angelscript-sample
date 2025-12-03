namespace Trace
{
	/**
	 * Init a trace that responds as if the player was trying to move between two locations.
	 * 
	 * NOTE: Even if the player's collision is currently blocked, this will still return hits
	 * as if the player had normal collision.
	 */
	FHazeTraceSettings InitFromPlayer(AHazePlayerCharacter Player, FName CustomTraceTag = NAME_None)
	{
		FHazeTraceSettings Settings;
		Settings.TraceWithPlayer(Player, CustomTraceTag);
		return Settings;
	}

	/**
	 * Init a trace that uses a movement component to represent an actor.
	 * The trace will be done at an offset from the movement's shape, so pass the actor location for start and end.
	 */
	FHazeTraceSettings InitFromMovementComponent(const UHazeMovementComponent MoveComp, FName CustomTraceTag = NAME_None)
	{
		FHazeTraceSettings Settings;
		Settings.TraceWithMovementComponent(MoveComp, CustomTraceTag);
		return Settings;
	}
}

/**
 * Setup a trace that responds as if the player was trying to move between two locations.
 * 
 * NOTE: Even if the player's collision is currently blocked, this will still return hits
 * as if the player had normal collision.
 */
mixin void TraceWithPlayer(FHazeTraceSettings& Settings, AHazePlayerCharacter Player, FName CustomTraceTag = NAME_None)
{
	Settings.TraceWithMovementComponent(
		UHazeMovementComponent::Get(Player),
		CustomTraceTag
	);

	if (Player.CapsuleComponent.GetCollisionProfileName() == n"PlayerCharacterOverlapOnly")
		Settings.TraceWithProfile(Player.CapsuleComponent.GetNonOverrideCollisionProfile());
	else
		Settings.TraceWithProfileFromComponent(Player.CapsuleComponent);
}

/**
 * Setup a trace that uses a movement component to represent an actor.
 * The trace will be done at an offset from the movement's shape, so pass the actor location for start and end.
 */
mixin void TraceWithMovementComponent(FHazeTraceSettings& Settings, const UHazeMovementComponent MoveComp, FName CustomTraceTag = NAME_None)
{
	Settings = MovementTrace::Init(MoveComp, CustomTraceTag).ConvertToTraceSettings();
}

mixin void IgnorePlayers(FHazeTraceSettings& Settings)
{
	Settings.IgnoreActor(Game::Mio);
	Settings.IgnoreActor(Game::Zoe);
}

mixin void TraceWithPlayerProfile(FHazeTraceSettings& Settings, AHazePlayerCharacter Player)
{
	if (Player.CapsuleComponent.GetCollisionProfileName() == n"PlayerCharacterOverlapOnly")
		Settings.TraceWithProfile(Player.CapsuleComponent.GetNonOverrideCollisionProfile());
	else
		Settings.TraceWithProfileFromComponent(Player.CapsuleComponent);
}