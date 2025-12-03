class ASketchbookArrowFire : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USketchbookDarkCaveCutoutComponent CutoutComp;

	UPROPERTY(EditDefaultsOnly)
	const float RadiusDecreaseRate = 50;

	UPROPERTY(EditDefaultsOnly)
	const float PutOutRate = 400;

	ASketchbookArrow Arrow;
	bool bDetached = false;


	void AttachToArrow(ASketchbookArrow ArrowToAttach)
	{
		Arrow = ArrowToAttach;
		AttachToActor(Arrow);
	}
	
	void Detach()
	{
		DetachFromActor();
		bDetached = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Arrow != nullptr)
		{
			if(bDetached)
			{
				CutoutComp.Radius -= PutOutRate * DeltaSeconds;
			}
			else
			{
				CutoutComp.Radius -= RadiusDecreaseRate * DeltaSeconds;
				
				if(Arrow.GetArrowState() != ESketchbookArrowState::Launched)
				{
					Detach();
				}
			}

			if(CutoutComp.Radius <= 0)
			{
				DestroyActor();
			}
		}
		else
		{
			DestroyActor();
		}
	}
};