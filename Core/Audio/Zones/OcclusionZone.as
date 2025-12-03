
UCLASS(Meta = (NoSourceLin), HideCategories = "Collision Rendering Cooking Debug")
class AOcclusionZone : AHazeAudioZone
{
	default SetTickGroup(ETickingGroup::TG_PostUpdateWork);
	default ZoneType = EHazeAudioZoneType::Occlusion;
	default BrushComponent.SetCollisionProfileName(n"AudioZone");
	// Won't be changed by users
	default Relevance = 1;
	default ZoneFadeTargetValue = 1.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "ZoneOcclusion";
	default EditorIcon.RelativeScale3D = FVector(2);
#endif


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		AudioZone::OnBeginPlay(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MoveZoneRtpcToTarget(ZoneFadeTargetValue, DeltaSeconds);

		if (!bShouldTick && ZoneRTPCValue == ZoneFadeTargetValue)
		{
			SetZoneTickEnabled(false);
		}
	}

}