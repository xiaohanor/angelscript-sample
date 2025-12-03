
UCLASS(Abstract)
class UWorld_Island_Rift_Platform_IslandSpinningDanger_Horizontal_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable)
	UHazeAudioEmitter FirstLaserCloseEmitter;

	UPROPERTY(NotEditable)
	UHazeAudioEmitter FirstLaserDistantEmitter;

	UPROPERTY(NotEditable)
	UHazeAudioEmitter SecondLaserCloseEmitter;

	UPROPERTY(NotEditable)
	UHazeAudioEmitter SecondLaserDistantEmitter;

	UPROPERTY(NotEditable)
	UHazeAudioEmitter FirstMetalArmEmitter;

	UPROPERTY(NotEditable)
	UHazeAudioEmitter SecondMetalArmEmitter;

	private UPrimitiveComponent ShieldRoot;
	private UStaticMeshComponent FirstLaserMesh;
	private UStaticMeshComponent SecondLaserMesh;

	TArray<FAkSoundPosition> FirstLaserSoundPositions;
	default FirstLaserSoundPositions.SetNum(2);
	TArray<FAkSoundPosition> SecondLaserSoundPositions;
	default SecondLaserSoundPositions.SetNum(2);

	UFUNCTION(BlueprintEvent)
	void OnPassbyTrigger(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return ShieldRoot.IsHiddenInGame();
	}

	UFUNCTION()
	private void OnPlayerOverlapPassbyTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in HitResult)
	{
		OnPassbyTrigger(Cast<AHazePlayerCharacter>(OtherActor));
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		UPrimitiveComponent::Get(HazeOwner, n"PassbyTrigger1").OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerOverlapPassbyTrigger");
		UPrimitiveComponent::Get(HazeOwner, n"PassbyTrigger2").OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerOverlapPassbyTrigger");

		ShieldRoot = Cast<UPrimitiveComponent>(HazeOwner.RootComponent);
		FirstLaserMesh = UStaticMeshComponent::Get(HazeOwner, n"AudioCollider1");
		SecondLaserMesh = UStaticMeshComponent::Get(HazeOwner, n"AudioCollider2");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto Player : Game::GetPlayers())
		{
			FVector ClosestLaserPlayerPos1;
			FVector ClosestLaserPlayerPos2;

			FirstLaserMesh.GetClosestPointOnCollision(Player.ActorLocation, ClosestLaserPlayerPos1);
			SecondLaserMesh.GetClosestPointOnCollision(Player.ActorLocation, ClosestLaserPlayerPos2);

			FirstLaserSoundPositions[Player.Player].SetPosition(ClosestLaserPlayerPos1);
			SecondLaserSoundPositions[Player.Player].SetPosition(ClosestLaserPlayerPos2);
		}

		FirstLaserCloseEmitter.AudioComponent.SetMultipleSoundPositions(FirstLaserSoundPositions);
		SecondLaserCloseEmitter.AudioComponent.SetMultipleSoundPositions(SecondLaserSoundPositions);
	}	
}