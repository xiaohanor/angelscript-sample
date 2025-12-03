// This actor is attached to the player.
// It is a separate because centipede is just a player component and a centipede actor shared by both players.
UCLASS(Abstract)
class APlayerCentipedeCollision : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Collision;
	default Collision.SphereRadius = 100.0;
}