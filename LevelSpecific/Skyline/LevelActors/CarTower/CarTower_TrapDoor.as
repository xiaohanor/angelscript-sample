UCLASS(Abstract)
class ACarTower_TrapDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UStaticMeshComponent TrapdoorMesh;

	UPROPERTY(DefaultComponent,Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;
	

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceComp.AddDisabler(this);
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleOnConstrainHit");
	}

	UFUNCTION()
	private void HandleOnConstrainHit(float Strength)
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	void RemoveForceDisabler()
	{
		ForceComp.RemoveDisabler(this);
	}

};
