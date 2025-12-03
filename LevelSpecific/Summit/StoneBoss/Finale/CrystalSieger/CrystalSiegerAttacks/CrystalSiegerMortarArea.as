class UCrystalSiegerMortarAreaVisualComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCrystalSiegerMortarAreaVisualDudComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto MortarArea = Cast<ACrystalSiegerMortarArea>(Component.Owner);

		if (MortarArea == nullptr)
			return;

		DrawWireBox(MortarArea.ActorLocation, MortarArea.Bounds, MortarArea.ActorRotation.Quaternion(), FLinearColor::Blue, 8.0, false);
	}
}

class UCrystalSiegerMortarAreaVisualDudComponent : UActorComponent
{

}

class ACrystalSiegerMortarArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5));
	default Visual.SpriteName = "SkullAndBones";
#endif

	UPROPERTY(DefaultComponent)
	UCrystalSiegerMortarAreaVisualDudComponent DudComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ACrystalSiegerMortar> SiegeMortarClass;

	FVector Bounds = FVector(450, 550, 5);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void SpawnTargetedMortar(FVector SpawnLocation, AHazePlayerCharacter TargetPlayer, AActor Initiator)
	{
		auto Mortar = SpawnActor(SiegeMortarClass, SpawnLocation, bDeferredSpawn = true);
		auto MoveComp = UHazeMovementComponent::Get(TargetPlayer);
		FVector GroundTarget = MoveComp.GetPreviousGroundContact().ImpactPoint;
		Mortar.Target = GroundTarget;
		Mortar.Initiator = Initiator;
		FinishSpawningActor(Mortar); 
	}

	void SpawnRandomMortar(FVector SpawnLocation, AActor Initiator)
	{
		auto Mortar = SpawnActor(SiegeMortarClass, SpawnLocation, bDeferredSpawn = true);
		Mortar.Target = GetRandomTargetLocation();
		Mortar.Initiator = Initiator;
		FinishSpawningActor(Mortar); 
	}

	FVector GetRandomTargetLocation()
	{
		FVector Target = ActorLocation;
		FVector HalfBounds = Bounds / 2;
		float RX = Math::RandRange(-HalfBounds.X, HalfBounds.X);
		float YX = Math::RandRange(-HalfBounds.Y, HalfBounds.Y);
		float ZX = Math::RandRange(-HalfBounds.Z, HalfBounds.Z);
		Target += ActorForwardVector * RX;
		Target += ActorRightVector * YX;
		Target += ActorUpVector * ZX;
		return Target;
	}
};