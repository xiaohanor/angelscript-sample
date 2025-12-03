
class UWardrobeChangeTestRoot : USceneComponent
{
	default bTickInEditor = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Owner == nullptr)
			return;

		AWardrobeChangeTest OwnerWardrobe =  Cast<AWardrobeChangeTest>(Owner);

		if(OwnerWardrobe == nullptr)
			return;

		OwnerWardrobe.TickInEdtor(DeltaSeconds);
	}
}

class AWardrobeChangeTest : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UWardrobeChangeTestRoot RootComp;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent Mesh_Fantasy;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent Mesh_SciFi;

	// --------------------------
	// --------------------------

	UPROPERTY(EditAnywhere, Category = "Blend")
	FHazeTimeLike BlendTimeLike;
	default BlendTimeLike.Duration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Blend")
	float PlayRate = 1.0;
	
	UPROPERTY(EditAnywhere, Category = "Blend")
	EAttachkedObjectsStart AttachkedObjectsStart = EAttachkedObjectsStart::AfterDelay;

	UPROPERTY(EditAnywhere, Category = "Blend")
	float Delay = 0.0;

	UPROPERTY(EditAnywhere, Category = "Blend")
	FVector BlendDirection = FVector(0, 0, 1);

	UPROPERTY(EditAnywhere, Category = "Blend")
	bool bWorldSpace = false;

	UPROPERTY()
	FSciFiTutorialBlendObjectFinishedBlendEvent OnFinishedBlend;

	UPROPERTY()
	bool bActivatedBlend = false;

	UFUNCTION(BlueprintEvent)
	void TickInEdtor(const float Dt)
	{
		// PrintToScreen("WHY U NO WOOOOOOOOOOOOOORK");
	}

	UFUNCTION()
	void ResetWhiteSpaceBlend(UHazeCharacterSkeletalMeshComponent Mesh)
	{
		PrintToScreen("WHY U NO WOOOOOOOOOOOOOORK");
	}

	UFUNCTION()
	void SetWhiteSpaceBlend(UHazeCharacterSkeletalMeshComponent Mesh, float Alpha, FVector Direction = FVector::UpVector, bool bLocalSpace = true)
	{
		Mesh.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", Alpha);

		FVector WhitSpaceBlendDirection = Direction;
		if(bLocalSpace)
			WhitSpaceBlendDirection = Mesh.WorldTransform.TransformVector(Direction);

		WhitSpaceBlendDirection.Normalize();
		WhitSpaceBlendDirection *= 0.8;

		Mesh.SetVectorParameterValueOnMaterials(n"WhitespaceBlendDirection", WhitSpaceBlendDirection);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		return; 

		// Mesh_Fantasy.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", 0);
		// Mesh_SciFi.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", 0);

		// if(bWorldSpace)
		// 	BlendDirection = BlendDirection;
		// else
		// 	BlendDirection = Mesh_Fantasy.WorldTransform.TransformVector(BlendDirection);

		// BlendDirection.Normalize();
		// BlendDirection *= 0.8;

		// Mesh_Fantasy.SetVectorParameterValueOnMaterials(n"WhitespaceBlendDirection", BlendDirection);
		// Mesh_SciFi.SetVectorParameterValueOnMaterials(n"WhitespaceBlendDirection", BlendDirection);
		
		// BlendTimeLike.SetPlayRate(PlayRate);
		// BlendTimeLike.BindUpdate(this, n"UpdateBlend");
		// BlendTimeLike.BindFinished(this, n"FinishBlend");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// PrintToScreen("HHHHHHHHHHHHHHHHHHHEl");
		// Mesh_Fantasy.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", 1);
		// Mesh_SciFi.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", 1);
	}

	UFUNCTION()
	void ResetBlend()
	{
		if (!bActivatedBlend)
			return;
		
		bActivatedBlend = false;
		delayTimer.ClearTimer();

		Mesh_Fantasy.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", 0);
		Mesh_SciFi.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", 0);

		TArray<AActor> ChildActors;
		GetAttachedActors(ChildActors);
		for (AActor Actor : ChildActors)
		{
			ASciFiTutorialBlendObject BlendObject = Cast<ASciFiTutorialBlendObject>(Actor);
			if(BlendObject != nullptr)
				BlendObject.ResetBlend();
		}
	}
	
	FTimerHandle delayTimer;

	UFUNCTION()
	void StartBlend()
	{
		if (bActivatedBlend)
			return;

		bActivatedBlend = true;
		
		if(Delay != 0)
			Timer::SetTimer(this, n"FinishDelay", Delay);
		else
			FinishDelay();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateBlend(float CurValue)
	{
		Mesh_Fantasy.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", CurValue);
		Mesh_SciFi.SetScalarParameterValueOnMaterials(n"WhitespaceBlend", CurValue);
		PrintToScreen("BlendSpace Val: " + CurValue);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishBlend()
	{
		OnFinishedBlend.Broadcast();
		if(AttachkedObjectsStart == EAttachkedObjectsStart::AfterBlend)
		{
			TArray<AActor> ChildActors;
			GetAttachedActors(ChildActors);
			for (AActor Actor : ChildActors)
			{
				ASciFiTutorialBlendObject BlendObject = Cast<ASciFiTutorialBlendObject>(Actor);
				if(BlendObject != nullptr)
					BlendObject.StartBlend();
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishDelay()
	{
		BlendTimeLike.PlayFromStart();

		if(AttachkedObjectsStart == EAttachkedObjectsStart::AfterDelay)
		{
			TArray<AActor> ChildActors;
			GetAttachedActors(ChildActors);
			for (AActor Actor : ChildActors)
			{
				ASciFiTutorialBlendObject BlendObject = Cast<ASciFiTutorialBlendObject>(Actor);
				if(BlendObject != nullptr)
					BlendObject.StartBlend();
			}
		}
	}

}