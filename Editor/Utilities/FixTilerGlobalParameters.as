class UFixTilerglobalParameters : UScriptAssetMenuExtension
{
	default SupportedClasses.Add(UMaterialInstanceConstant);

	void PatchTexture(UMaterialInstanceConstant Mat, FName From, FName To)
	{
		UTexture Temp = Mat.GetTextureParameterValue(From);
		if(Temp != MaterialEditing::GetMaterialDefaultTextureParameterValue(Mat.BaseMaterial, From))
			MaterialEditing::SetMaterialInstanceTextureParameterValue(Mat, To, Temp);
	}

	void PatchFloat(UMaterialInstanceConstant Mat, FName From, FName To)
	{
		float Temp = Mat.GetScalarParameterValue(From);
		if(Temp != MaterialEditing::GetMaterialDefaultScalarParameterValue(Mat.BaseMaterial, From))
			MaterialEditing::SetMaterialInstanceScalarParameterValue(Mat, To, Temp);
	}

	void PatchVectorParameter(UMaterialInstanceConstant Mat, FName From, FName To)
	{
		FLinearColor Temp = Mat.GetVectorParameterValue(From);
		if(Temp != MaterialEditing::GetMaterialDefaultVectorParameterValue(Mat.BaseMaterial, From))
			MaterialEditing::SetMaterialInstanceVectorParameterValue(Mat, To, Temp);
	}

	bool ParameterIsDifferentFromDefault(UMaterialInstanceConstant Mat, FName From)
	{
		float Temp = Mat.GetScalarParameterValue(From);
		float Default =  MaterialEditing::GetMaterialDefaultScalarParameterValue(Mat.BaseMaterial, From);
		if(Temp != Default)
			return true;
		return false;
	}

	//UFUNCTION(CallInEditor)
	void PatchTiling()
	{
		TArray<UObject> Things = EditorUtility::GetSelectedAssets();
		int count = Things.Num();
		for(UObject Thing : Things)
		{
			UMaterialInstanceConstant ThingMat = Cast<UMaterialInstanceConstant>(Thing);
			if(ThingMat == nullptr)
				continue;
			
			if(ThingMat.BaseMaterial == nullptr)
				continue;
			//(ThingMat.BaseMaterial.Name == n"Env_Tiler") || (ThingMat.BaseMaterial.Name == n"Env_Prop") || 
			if((ThingMat.BaseMaterial.Name == n"Env_Landscape"))
			{
				PatchFloat(ThingMat, n"TilingX", n"Tiling");

				PatchFloat(ThingMat, n"Tiler_A_TilingX", n"Tiler_A_Tiling");
				PatchFloat(ThingMat, n"Tiler_B_TilingX", n"Tiler_B_Tiling");
				PatchFloat(ThingMat, n"Tiler_C_TilingX", n"Tiler_C_Tiling");
				PatchFloat(ThingMat, n"Tiler_D_TilingX", n"Tiler_D_Tiling");

				PatchFloat(ThingMat, n"Layer_A_TilingX", n"Layer_A_Tiling");
				PatchFloat(ThingMat, n"Layer_B_TilingX", n"Layer_B_Tiling");
				PatchFloat(ThingMat, n"Layer_C_TilingX", n"Layer_C_Tiling");
				PatchFloat(ThingMat, n"Layer_D_TilingX", n"Layer_D_Tiling");
				PatchFloat(ThingMat, n"Layer_E_TilingX", n"Layer_E_Tiling");
				PatchFloat(ThingMat, n"Layer_F_TilingX", n"Layer_F_Tiling");
				PatchFloat(ThingMat, n"Layer_G_TilingX", n"Layer_G_Tiling");
				PatchFloat(ThingMat, n"Layer_H_TilingX", n"Layer_H_Tiling");
			}
		}
	}

#if EDITOR
	//UFUNCTION(CallInEditor)
	void IsAdvancedTiler()
	{
		UMaterialInterface Env_Tiler = Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/Surface/Env_Tiler.Env_Tiler"));

		int i = 0;
		int j = 0;
		int AdvancedCount = 0;
		int NormalCount = 0;
		TArray<UObject> Things = EditorUtility::GetSelectedAssets();
		int count = Things.Num();
		for(UObject Thing : Things)
		{
			i++;
			UMaterialInstanceConstant ThingMat = Cast<UMaterialInstanceConstant>(Thing);
			if(ThingMat == nullptr)
				continue;
			
			if(ThingMat.Parent == nullptr)
				continue;
		
			if((ThingMat.Parent.Name == n"Env_Tiler_Advanced"))
			{
				bool Advanced = false;
				if(ParameterIsDifferentFromDefault(ThingMat, n"HazeToggleCategory_Tiler_C_Enabled"))
					Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"HazeToggleCategory_Tiler_D_Enabled"))
					Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"HazeToggle_TopMaskIsObjectLocal"))
					Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"HazeToggle_TopMaskIsObjectLocal"))
					Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"Tiler_A_Env_IridescenceDepth")) Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"Tiler_B_Env_IridescenceDepth")) Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"Tiler_C_Env_IridescenceDepth")) Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"Tiler_D_Env_IridescenceDepth")) Advanced = true;

				if(ParameterIsDifferentFromDefault(ThingMat, n"Tiler_A_Env_IridescenceStrength")) Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"Tiler_B_Env_IridescenceStrength")) Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"Tiler_C_Env_IridescenceStrength")) Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"Tiler_D_Env_IridescenceStrength")) Advanced = true;

				if(ParameterIsDifferentFromDefault(ThingMat, n"HazeToggle_Tiler_A_AntiTiling")) Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"HazeToggle_Tiler_B_AntiTiling")) Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"HazeToggle_Tiler_C_AntiTiling")) Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"HazeToggle_Tiler_D_AntiTiling")) Advanced = true;

				if(ParameterIsDifferentFromDefault(ThingMat, n"Tiler_A_Fuzz")) Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"Tiler_B_Fuzz")) Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"Tiler_C_Fuzz")) Advanced = true;
				if(ParameterIsDifferentFromDefault(ThingMat, n"Tiler_D_Fuzz")) Advanced = true;
				
				if(Advanced)
				{
					Print("TRUE " + i + "/" + count + ", j: " + j + ", " + ThingMat.Name);
					AdvancedCount++;
				}
				else
				{
					Print("FALSE " + i + "/" + count + ", j: " + j + ", " + ThingMat.Name);
					NormalCount++;
					MaterialEditing::SetMaterialInstanceParent(ThingMat, Env_Tiler);
				}
				j++;
			}
			
		}
		Print(""+AdvancedCount);
		Print(""+NormalCount);
	}
#endif
	
	//UFUNCTION(CallInEditor)
	void FixGlobals()
	{
		
		TArray<UObject> Things = EditorUtility::GetSelectedAssets();
		for(UObject Thing : Things)
		{
			UMaterialInstanceConstant ThingMat = Cast<UMaterialInstanceConstant>(Thing);
			if(ThingMat == nullptr)
				continue;

			//if(ThingMat.Parent.Name.ToString().StartsWith("Env_Tiler"))
			{
				//PatchTexture(ThingMat, n"TexM2", n"Global_TexM2");
				//PatchTexture(ThingMat, n"TexM6", n"Global_TexM6");
				//PatchTexture(ThingMat, n"TexM4", n"Global_TexM4");
				//PatchFloat(ThingMat, n"WorldHeightRange", n"Global_WorldHeightRange");
				//PatchFloat(ThingMat, n"WorldHeight", n"Global_WorldHeight");
				//PatchFloat(ThingMat, n"HazeToggle_DistanceFieldNormals", n"HazeToggle_Global_DistanceFieldNormals");
				//PatchFloat(ThingMat, n"HazeToggle_TopMaskIsObjectLocal", n"HazeToggle_Global_TopMaskIsObjectLocal");
				//PatchFloat(ThingMat, n"DistanceFieldNormalsRange", n"Global_DistanceFieldNormalsRange");
				//PatchFloat(ThingMat, n"UV_Channel", n"Global_UV_Channel");
				//PatchFloat(ThingMat, n"Mask_UV_Channel", n"Global_Mask_UV_Channel");
				//PatchFloat(ThingMat, n"ScaleMin", n"Global_ScaleMin");
				//PatchFloat(ThingMat, n"ScaleMax", n"Global_ScaleMax");
				//PatchFloat(ThingMat, n"ParallaxDepth", n"Global_ParallaxDepth");
				//PatchVectorParameter(ThingMat, n"ParallaxVertexColor", n"Global_ParallaxVertexColor");
				
				PatchFloat(ThingMat, n"Tiler_A_Env_SubsurfaceStrength", n"Tiler_A_SubsurfaceStrength");
				PatchFloat(ThingMat, n"Tiler_B_Env_SubsurfaceStrength", n"Tiler_B_SubsurfaceStrength");
				PatchFloat(ThingMat, n"Tiler_C_Env_SubsurfaceStrength", n"Tiler_C_SubsurfaceStrength");
				PatchFloat(ThingMat, n"Tiler_D_Env_SubsurfaceStrength", n"Tiler_D_SubsurfaceStrength");
				PatchVectorParameter(ThingMat, n"Tiler_A_Env_SubsurfaceColor", n"Tiler_A_SubsurfaceColor");
				PatchVectorParameter(ThingMat, n"Tiler_B_Env_SubsurfaceColor", n"Tiler_B_SubsurfaceColor");
				PatchVectorParameter(ThingMat, n"Tiler_C_Env_SubsurfaceColor", n"Tiler_C_SubsurfaceColor");
				PatchVectorParameter(ThingMat, n"Tiler_D_Env_SubsurfaceColor", n"Tiler_D_SubsurfaceColor");
				
			}

		}
	}
}
