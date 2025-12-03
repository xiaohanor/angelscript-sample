class UAnimInstanceTundraCutsceneShapeshift : UHazeAnimInstanceBase
{

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCopyPoseFromMesh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BlendTime = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector Scale = FVector::OneVector;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ScaleAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTundraCutsceneShapeshiftData ShapeshiftData;

	UHazeAnimCopyPoseFromMeshComponent CopyPoseFromMeshComp;
	UTundraCutsceneShapeshiftComponent ShapeshiftComp;

	float ShapeshiftAlpha;
	float TimeLapsed;

	int TickCounter = 0;

	bool bShapeshifting;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		ShapeshiftComp = UTundraCutsceneShapeshiftComponent::GetOrCreate(HazeOwningActor);
		ShapeshiftComp.OnShapeshift.Clear();
		ShapeshiftComp.OnShapeshift.AddUFunction(this, n"OnShapeshift");
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (!bShapeshifting)
			return;

		if (TickCounter >= 1)
		{
			ShapeshiftAlpha = TimeLapsed / ShapeshiftData.BlendTime;
			TimeLapsed += DeltaTime;
		}

		if (ShapeshiftData.bShapeshiftingTo)
		{
			if (TickCounter == 1)
			{
				bCopyPoseFromMesh = false;
				BlendTime = ShapeshiftData.BlendTime;
				OwningComponent.RemoveTickPrerequisiteComponent(ShapeshiftData.SourceSkelMesh);
			}
		}
		else
		{
			if (TickCounter == 2)
			{
				bCopyPoseFromMesh = true;
				OwningComponent.AddTickPrerequisiteComponent(ShapeshiftData.SourceSkelMesh);
				BlendTime = 0.03;
			}
			ScaleAlpha = ShapeshiftAlpha;
		}

		TickCounter++;
	}

	UFUNCTION()
	void OnShapeshift(FTundraCutsceneShapeshiftData InShapeshiftData)
	{
		ShapeshiftData = InShapeshiftData;

		Scale = FVector(ShapeshiftData.Scale);

		bShapeshifting = true;
		TickCounter = 0;
		TimeLapsed = 0;

		BlendTime = 0;
		if (ShapeshiftData.bShapeshiftingTo)
		{
			bCopyPoseFromMesh = true;
			OwningComponent.AddTickPrerequisiteComponent(ShapeshiftData.SourceSkelMesh);
			ScaleAlpha = 1;
		}
		else
		{
			bCopyPoseFromMesh = false;
		}
	}

	UFUNCTION()
	void OnShapeshiftComplete()
	{
		OwningComponent.RemoveTickPrerequisiteComponent(ShapeshiftData.SourceSkelMesh);
	}
}