UCLASS(Abstract)
class AGenericGoat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent GoatRoot;

	UPROPERTY(DefaultComponent, Attach = GoatRoot)
	UStaticMeshComponent GoatMesh;

	UPROPERTY(DefaultComponent, Attach = GoatMesh)
	UArrowComponent LeftEyeComp;

	UPROPERTY(DefaultComponent, Attach = GoatMesh)
	UArrowComponent RightEyeComp;

	UPROPERTY(DefaultComponent, Attach = GoatRoot)
	USceneComponent FrontLeftLegRoot;

	UPROPERTY(DefaultComponent, Attach = GoatRoot)
	USceneComponent FrontRightLegRoot;

	UPROPERTY(DefaultComponent, Attach = GoatRoot)
	USceneComponent BackLeftLegRoot;

	UPROPERTY(DefaultComponent, Attach = GoatRoot)
	USceneComponent BackRightLegRoot;

	AHazePlayerCharacter MountedPlayer;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
	}
}