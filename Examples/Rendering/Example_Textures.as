/*
	This way, you can create and update existing textures with data from the game.
	It's only reccomended for small textures. If you need to update a large texture, see Example_RenderTextures.as
*/
UCLASS()
class AExample_Textures : AActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComponent;
	
	// 8-bit unsigned int (0.0 to 1.0)
	UPROPERTY(EditAnywhere)
	UTexture2D TestTextureUint8;

	// 32-bit float (-inf to +inf)
	UPROPERTY(EditAnywhere)
	UTexture2D TestTextureFloat32;

	int Size = 16;

	TArray<FVector4f> Data = TArray<FVector4f>();

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		// Create textures
		TestTextureUint8 = Rendering::CreateTexture2D(Size, Size, TextureCompressionSettings::TC_VectorDisplacementmap);
		TestTextureFloat32 = Rendering::CreateTexture2D(Size, Size, TextureCompressionSettings::TC_HDR_F32);
		
		// Create backing array
		Data.SetNum(Size * Size);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Update backing array
		for (int x = 0; x < Size; x++)
		{
			for (int y = 0; y < Size; y++)
			{
				float R = Math::Frac((x / float(Size)) + Time::GameTimeSeconds * 0.5);
				float G = Math::Frac((y / float(Size)) + Math::Sin(Time::GameTimeSeconds));
				float B = Math::Abs(Math::Sin(Time::GameTimeSeconds * 0.25));
				Data[x+y*Size] = FVector4f(float32(R), float32(G), float32(B), 1);
			}
		}
		
		// Update Texture with the new array.
		Rendering::UpdateTexture2D(TestTextureUint8, Data);
		Rendering::UpdateTexture2D(TestTextureFloat32, Data);
	}
}