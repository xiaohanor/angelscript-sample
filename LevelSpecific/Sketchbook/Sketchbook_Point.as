UCLASS(Abstract)
class ASketchbook_Point : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(EditAnywhere)
	ASketchbookColorizeActor ColorizeActor;
	
	UPROPERTY()
	bool bIsPaint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ColorizeActor.AddTotalPaintPoint();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(GetDistanceTo(Game::GetClosestPlayer(ActorLocation)) < 200 && !bIsPaint)
		{
			bIsPaint = true;
			ColorizeActor.AddPaintPoints();
			Print(""+ColorizeActor.PaintPoints);
		}

		// if(bIsPaint)
		// 	Debug::DrawDebugSphere(ActorLocation,10,12,FLinearColor(0,1,0));
		// else
		// 	Debug::DrawDebugSphere(ActorLocation,10,12,FLinearColor(1,0,0));
	}
};