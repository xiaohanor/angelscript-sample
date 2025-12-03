delegate void FMeltdownScreenWalkTransitionSignature();

struct FMeltdownScreenWalkTransitionData
{
	AMeltdownScreenWalkDisplayPlane Plane;
	ARespawnPoint EndPosition;
	AHazeCameraActor Camera;
	UHazePlayerVariantAsset Outfit;
	FMeltdownScreenWalkTransitionSignature OnCompleted;
}

class UMeltdownScreenWalkTransitionComponent : UActorComponent
{
	FMeltdownScreenWalkTransitionData Data;
	bool bTransition = false;

	void StartTransition(AMeltdownScreenWalkDisplayPlane _Plane, ARespawnPoint _EndPosition, AHazeCameraActor _Camera, UHazePlayerVariantAsset _Outfit, FMeltdownScreenWalkTransitionSignature _OnCompleted)
	{
		Data.Plane = _Plane;
		Data.EndPosition = _EndPosition;
		Data.Camera = _Camera;
		Data.Outfit = _Outfit;
		Data.OnCompleted = _OnCompleted;
		bTransition = true;
	}

	
};

namespace MeltdownScreenWalkTransition
{
	UFUNCTION()
	void StartMeltdownScreenWalkTransition(AMeltdownScreenWalkDisplayPlane Plane, ARespawnPoint EndPosition, AHazeCameraActor Camera, UHazePlayerVariantAsset Outfit, FMeltdownScreenWalkTransitionSignature OnCompleted)
	{
		UMeltdownScreenWalkTransitionComponent::Get(Game::Mio).StartTransition(Plane, EndPosition, Camera, Outfit, OnCompleted);
	}
}