UCLASS(Abstract)
class ATundraPlayerSnowMonkeyActor : AHazeCharacter
{
	default CapsuleComponent.CollisionProfileName = n"NoCollision";
	default Mesh.ShadowPriority = EShadowPriority::Player;

	AHazePlayerCharacter Player;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;
}