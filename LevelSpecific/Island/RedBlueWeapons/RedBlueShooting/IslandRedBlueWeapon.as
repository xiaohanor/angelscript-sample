
UCLASS(Abstract)
class AIslandRedBlueWeapon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default Mesh.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent Muzzle;
	default Muzzle.RelativeLocation = FVector(23.158321, 0.0, 5.0);

	UPROPERTY(BlueprintReadOnly, VisibleInstanceOnly)
	EIslandRedBlueWeaponType WeaponType = EIslandRedBlueWeaponType::MAX;

	UPROPERTY(BlueprintReadOnly, VisibleInstanceOnly)
	EIslandRedBlueWeaponHandType HandType = EIslandRedBlueWeaponHandType::MAX;

	UPROPERTY(BlueprintReadOnly, VisibleInstanceOnly)
	AHazePlayerCharacter PlayerOwner;
}