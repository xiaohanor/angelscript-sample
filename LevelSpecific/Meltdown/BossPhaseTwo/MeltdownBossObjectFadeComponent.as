class UMeltdownBossObjectFadeComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	TArray<UStaticMeshComponent> Meshes;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface BlendOverlay;
	UMaterialInstanceDynamic BlendOverlayDynamic;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazeTimeLike FadeTimeLike;

	UFUNCTION()
	void Fade(float CurrentValue)
	{
		for (int i = 0; i < Meshes.Num(); i++)
		{
			Meshes[i].SetScalarParameterValueOnMaterials(n"DitherFade", CurrentValue);
		}

		if(BlendOverlay != nullptr)
		{
			BlendOverlayDynamic.SetScalarParameterValue(n"Blend", CurrentValue);
		}
	}

	UFUNCTION()
	void FadeIn()
	{
		if(BlendOverlay != nullptr)
		{
			BlendOverlayDynamic = Material::CreateDynamicMaterialInstance(this, BlendOverlay, n"BlendOverlayDynamic");
			
			for (int i = 0; i < Meshes.Num(); i++)
			{
				Meshes[i].SetOverlayMaterial(BlendOverlayDynamic);
			}
		}
		
		FadeTimeLike.Duration = 1;
		FadeTimeLike.Curve.AddDefaultKey(0,0);
		FadeTimeLike.Curve.AddDefaultKey(1,1);
		FadeTimeLike.BindUpdate(this, n"Fade");
		FadeTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void FadeOut()
	{
		FadeTimeLike.ReverseFromEnd();
	}
};