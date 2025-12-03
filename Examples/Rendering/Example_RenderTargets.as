/*
	The fastest way to update a large texture is to draw to it with the GPU.
*/

UCLASS()
class AExample_RenderTargets : AActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComponent;
	
	UPROPERTY(EditAnywhere, Category = "Draw Canvas")
	UTextureRenderTarget2D CanvasTarget;
	
	UPROPERTY(EditAnywhere, Category = "Draw Canvas")
	UTexture2D MyTexture;


	UPROPERTY(EditAnywhere, Category = "Draw Material")
	UMaterialInterface MyMaterial;

	UPROPERTY(EditAnywhere, Category = "Draw Material")
	UTextureRenderTarget2D MaterialTarget;


	UPROPERTY(EditAnywhere, Category = "Rock Paper Scissors")
	UTextureRenderTarget2D SwapTarget0;

	UPROPERTY(EditAnywhere, Category = "Rock Paper Scissors")
	UTextureRenderTarget2D SwapTarget1;

	UPROPERTY(EditAnywhere, Category = "Rock Paper Scissors")
	UMaterialInterface RockPaperScissors;

	UMaterialInstanceDynamic RockPaperScissorsDynamic;

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		CanvasTarget = Rendering::CreateRenderTarget2D(1024, 1024);
		MaterialTarget = Rendering::CreateRenderTarget2D(1024, 1024);

		SwapTarget0 = Rendering::CreateRenderTarget2D(64, 64);
		SwapTarget1 = Rendering::CreateRenderTarget2D(64, 64);

		RockPaperScissors = Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/examples/Example_RenderTargets_RockPaperScissors.Example_RenderTargets_RockPaperScissors"));
		RockPaperScissorsDynamic = Material::CreateDynamicMaterialInstance(this, RockPaperScissors);

		MyMaterial = Cast<UMaterialInterface>(LoadObject(nullptr, "/Game/MasterMaterials/Generated/examples/Example_RenderTargets.Example_RenderTargets"));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Clear the target to black
		Rendering::ClearRenderTarget2D(CanvasTarget, FLinearColor(0,0,0,1));


		// 1. The easiest way to draw to a RenderTarget is using a "Canvas". With this you can draw simple shapes and textures directly to it.
		UCanvas Canvas;
		FDrawToRenderTargetContext Context;
		FVector2D A;
		Rendering::BeginDrawCanvasToRenderTarget(CanvasTarget, Canvas, A, Context);

		// Draw some boxes
		float BoxX = Math::Lerp(500, 100, Math::Abs(Math::Sin(Time::GameTimeSeconds)));
		Canvas.DrawBox(FVector2D(BoxX, 100), FVector2D(125, 125), 50.0, FLinearColor(1,0,0,1));
		Canvas.DrawBox(FVector2D(200, 200), FVector2D(125, 125), 50.0, FLinearColor(0,1,0,1));
		Canvas.DrawBox(FVector2D(300, 300), FVector2D(125, 125), 50.0, FLinearColor(0,0,1,1));
		
		// Draw some lines
		Canvas.DrawLine(FVector2D(500, 500), FVector2D(800,300), 5);
		Canvas.DrawLine(FVector2D(500, 550), FVector2D(800,350), 5);
		
		// Draw a textured quad
		Canvas.DrawTexture(MyTexture, FVector2D(50, 580), FVector2D(400, 400), FVector2D(0, 0), FVector2D(1, 1), Rotation = 25.000000);

		// when done, you neeed to call this to "finish" rendering.
		Rendering::EndDrawCanvasToRenderTarget(Context);


		// 2. Another way is drawing to the whole target using a material. (See Example_RenderTargets.usf for the shader code.)
		Rendering::DrawMaterialToRenderTarget(MaterialTarget, MyMaterial);


		// 3. This can be used to create a feedback-loop, where the prevous texture is fed into the next iteration by swapping.
		// Read from Target 0
		RockPaperScissorsDynamic.SetTextureParameterValue(n"TexPrevious", SwapTarget0);
		// Draw to Target 1
		Rendering::DrawMaterialToRenderTarget(SwapTarget1, RockPaperScissorsDynamic);
		// Swap them.
		UTextureRenderTarget2D Temp = SwapTarget0;
		SwapTarget0 = SwapTarget1;
		SwapTarget1 = Temp;
	}
}