class UPlayerShellEffectHandler : UPlayerCoreMovementEffectHandler
{
	UPROPERTY(Category="Material", ToolTip="Select the material for the Shell Mesh")
	UMaterialInterface ShellMaterial;
	
	UPROPERTY(Category="Skeletal Mesh", ToolTip="Select a Skeletal Mesh for the Shell Mesh")
	USkeletalMesh ShellSkelMesh;

	UPROPERTY(Category ="Feet Material", ToolTip="Material to display on feet when wallrunning")
	UMaterialInterface FeetMaterial;

	USkeletalMeshComponent ShellComp;

	bool bWantToShowShell = false;
	bool bBlendingOutFeet = false;

	float SmoothstepAlpha = 1.0;
	float WallRunFeetAlpha = 1.0;
	
	UFUNCTION()
	void ShowFeet()
	{
		bBlendingOutFeet = false;
		WallRunFeetAlpha = 1.0;
		UMaterialInstanceDynamic Feet_MID = Material::CreateDynamicMaterialInstance(this, FeetMaterial);
		Player.Mesh.SetOverlayMaterial(Feet_MID);
	}

	UFUNCTION()
	void HideFeet()
	{
		Player.Mesh.SetOverlayMaterial(nullptr);
	}

	UFUNCTION()
	void FadeoutFeet()
	{
		bBlendingOutFeet = true;
		WallRunFeetAlpha=1.0;
	}

	UFUNCTION()
	void StartShell()
	{
		return;

		//TODO: I will remove this later, Tyko, i promise.
		//We don't need to go with this solution anymore..
		//..since we now have "Overlay Materials".

		//bWantToShowShell = true;
		//
		//if(ShellComp==nullptr)
		//{
		//	ShellComp = USkeletalMeshComponent::Create(Player);
		//	ShellComp.SetSkeletalMeshAsset(Player.Mesh.SkeletalMeshAsset);		//Use this if we want to use the current players mesh as the "Shell".
		//	//ShellComp.SetSkeletalMeshAsset(ShellSkelMesh);					//Use this if we want to select our own SkelMesh for the "Shell".
		//	ShellComp.AttachToComponent(Player.Mesh);
		//	ShellComp.SetLeaderPoseComponent(Player.Mesh);
		//
		//	for(int i = 0; i<ShellComp.NumMaterials; i++)
		//	{
		//		ShellComp.SetMaterial(i, ShellMaterial);
		//	}
		//} 
	}

	UFUNCTION()
	void StopShell()
	{
		//PrintToScreenScaled("STOP SHELL", 2.0f);
		Player.Mesh.SetOverlayMaterial(nullptr);
		bWantToShowShell = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//Step & Rolldash material logic.
		if(ShellComp!=nullptr)
		{
			if(bWantToShowShell)
			{
				SmoothstepAlpha = 1.0;
			}
			else 
			{
				SmoothstepAlpha -= DeltaTime*2.0;
			}

			if(SmoothstepAlpha>0.0)
			{
				ShellComp.SetScalarParameterValueOnMaterials(n"MainTex_Max", 1.0-SmoothstepAlpha);
				ShellComp.SetHiddenInGame(false);
			}
			else
			{
				ShellComp.SetHiddenInGame(true);
			}
		}

		//Feet lighting up during wallrunning logic.
		if(bBlendingOutFeet)
		{
			UMaterialInterface OverlayMaterial = Player.Mesh.GetOverlayMaterial();
			if(OverlayMaterial!=nullptr)
			{
				UMaterialInstanceDynamic MID = Cast<UMaterialInstanceDynamic>(OverlayMaterial);
				MID.SetScalarParameterValue(n"Global_Opacity", WallRunFeetAlpha);
				WallRunFeetAlpha -= DeltaTime;
				if(WallRunFeetAlpha<=0.0)
				{
					HideFeet();
					bBlendingOutFeet=false;
				}
			}
		}
	}
}