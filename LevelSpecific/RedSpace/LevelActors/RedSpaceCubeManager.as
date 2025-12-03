
class ARedSpaceCubeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditInstanceOnly)
	TArray<ARedSpaceCube> Cubes;

	bool bPreviewing = false;

#if EDITOR
	UFUNCTION(CallInEditor)
	void TogglePreviewTransforms()
	{
		bPreviewing = !bPreviewing;
		for (ARedSpaceCube Cube : Cubes)
		{
			Cube.bPreviewTarget = bPreviewing;
			Cube.RerunConstructionScripts();
		}
	}
#endif

	UFUNCTION()
	void MoveCubes()
	{
		for (ARedSpaceCube Cube : Cubes)
		{
			Cube.StartMoving();
		}
	}

	UFUNCTION()
	void RotateCubes()
	{
		for (ARedSpaceCube Cube : Cubes)
		{
			Cube.StartRotating();
		}
	}

	UFUNCTION()
	void ScaleCubes()
	{
		for (ARedSpaceCube Cube : Cubes)
		{
			Cube.StartScaling();
		}
	}

	UFUNCTION()
	void ActivateCubes()
	{
		for (ARedSpaceCube Cube : Cubes)
		{
			if (Cube.bMove)
				Cube.Move();
			if (Cube.bRotate)
				Cube.Rotate();
			if (Cube.bScale)
				Cube.Scale();
		}
	}
}