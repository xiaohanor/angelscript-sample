
// TODO: Add selection logic to tick, setup on beginplay, add animadata variables, add normal variables

class UPlayerPolevaultComponent : UActorComponent
{

	UPROPERTY()
	FPlayerGrappleData AnimData;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CamSettingCharge;
	UPROPERTY()
	UHazeCameraSettingsDataAsset CamSettingAnticipation;
	UPROPERTY()
	UHazeCameraSettingsDataAsset CamSettingJump;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> GrappleShake;
    UPROPERTY()
    UPlayerFloorMotionSettings MoveSettings;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;

    FVector StartLoc;
    FVector MiddleLoc;
    FVector EndLoc;
    bool bPolevault = false;
    bool bAnticipate = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	}

	void DrawDebugSpline(FHazeRuntimeSpline& InSpline)
	{
		// start spline point
		Debug::DrawDebugPoint(InSpline.Points[0], 20.0, FLinearColor::Green);

		// end spline point
		Debug::DrawDebugPoint(InSpline.Points.Last(), 20.0, FLinearColor::Blue);

		// draw all splint points that we've assigned
		for(FVector P : InSpline.Points)
			Debug::DrawDebugPoint(P, 10.0, FLinearColor::Purple);

		// Find 150 uniformerly distributed locations on the spline
		TArray<FVector> Locations;
		InSpline.GetLocations(Locations, 150);

		// Draw all locations that we've found on the spline
		for(FVector L : Locations)
			Debug::DrawDebugPoint(L, 5.0, FLinearColor::Yellow);

		// Draw a location moving along the spline based on elasped time
		Debug::DrawDebugPoint(InSpline.GetLocation((Time::GetGameTimeSeconds() * 0.2) % 1.0), 30.0, FLinearColor::White);
	}


}

struct FPlayerPolevaultData
{

}
