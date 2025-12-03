namespace RenderingHelpers
{
	void InitMaterial(UObject OwningObject, UMaterialInterface Source, UMaterialInstanceDynamic& Target)
	{
		if(Target == nullptr)    
			Target = Material::CreateDynamicMaterialInstance(OwningObject, Source);
	}

	void DrawMaterialToRenderTarget(UTexture Source, UTextureRenderTarget2D Destination, UMaterialInstanceDynamic Material)
	{
		Material.SetTextureParameterValue(n"InputTexture", Source);
		Rendering::DrawMaterialToRenderTarget(Destination, Material);
	}

	void CopyTexture(UTexture Source, UTextureRenderTarget2D Destination)
	{
		UCanvas canvas;
		FDrawToRenderTargetContext context;
		FVector2D a;
		Rendering::BeginDrawCanvasToRenderTarget(Destination, canvas, a, context);
		canvas.DrawTexture(Source, FVector2D(0,0), FVector2D(Destination.SizeX, Destination.SizeY), FVector2D(0,0), FVector2D(1,1), FLinearColor(1,1,1,1), EBlendMode::BLEND_Translucent, 0, FVector2D(0.5, 0.5));
		Rendering::EndDrawCanvasToRenderTarget(context);
	}
}

class UPingEffectComponent : USceneCaptureComponentCube
{
    UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D Target1;

    UPROPERTY(EditAnywhere)
	UTextureRenderTarget2D Target2;

    UPROPERTY(EditAnywhere)
	UMaterialInterface ConvertMaterial;
    UPROPERTY()
	UMaterialInstanceDynamic ConvertMaterialDynamic;

    UPROPERTY(EditAnywhere)
	UMaterialInterface BlurMaterial;
    UPROPERTY()
	UMaterialInstanceDynamic BlurMaterialDynamic;

    UPROPERTY(EditAnywhere)
	UMaterialInterface SobelMaterial;
    UPROPERTY()
	UMaterialInstanceDynamic SobelMaterialDynamic;

    UPROPERTY(EditAnywhere)
	UMaterialInterface CopyMaterial;
    UPROPERTY()
	UMaterialInstanceDynamic CopyMaterialDynamic;

	// Call this when the ping starts.
	UFUNCTION(CallInEditor)
	void Ping()
	{
		CaptureScene();
	}

	// Call this to update the texture
	UFUNCTION(CallInEditor)
	void Update(float Radius)
	{
		RenderingHelpers::InitMaterial(this, ConvertMaterial, ConvertMaterialDynamic);
		RenderingHelpers::InitMaterial(this, BlurMaterial, BlurMaterialDynamic);
		RenderingHelpers::InitMaterial(this, SobelMaterial, SobelMaterialDynamic);
		RenderingHelpers::InitMaterial(this, CopyMaterial, CopyMaterialDynamic);
		
		// Generate a mask
		ConvertMaterialDynamic.SetScalarParameterValue(n"Radius", Radius);
		RenderingHelpers::DrawMaterialToRenderTarget(TextureTarget, Target1, ConvertMaterialDynamic);

		// Blur
		RenderingHelpers::DrawMaterialToRenderTarget(Target1, Target2, BlurMaterialDynamic);

		// Sobel
		RenderingHelpers::DrawMaterialToRenderTarget(Target2, Target1, SobelMaterialDynamic);
	}

	float GetAlphaAtLocation(const FVector InWorldLocation) const
	{
		// I'm assuming that the sphere is attached to this component and has zero offset.
		FVector Direction = InWorldLocation - GetWorldLocation();
		Direction.Normalize();
		return GetAlphaAtDirection(Direction);
	}

	float GetAlphaAtDirection(const FVector InWorldDirection) const
	{
		FVector2D UV;
		OctEncode(InWorldDirection, UV);

		const float Alpha = Rendering::ReadRenderTargetUV(Target1, UV.X, UV.Y).ReinterpretAsLinear().B;

		return Alpha;
	}

	void OctEncode(FVector InDirection, FVector2D& OutUV) const
	{
		if(InDirection.IsZero())
			return; 

		FVector N = InDirection;
		N /= (Math::Abs(N.X) + Math::Abs(N.Y) + Math::Abs(N.Z));

		FVector2D N2D = FVector2D(N.X, N.Y);

		if(N.Z < 0.0)
		{
			FVector2D V = N2D;

			const FVector2D InvSwizzle = FVector2D::UnitVector - FVector2D(V.Y, V.X);

			N.X = InvSwizzle.X;
			N.Y = InvSwizzle.Y;

			if(V.X < 0.0)
				N2D.X *= -1.0;

			if(V.Y < 0.0)
				N2D.Y *= -1.0;

		}

		OutUV = N2D * 0.5 + 0.5;
	}

}

