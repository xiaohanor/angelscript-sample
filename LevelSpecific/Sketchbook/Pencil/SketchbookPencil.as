asset SketchbookPencilSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USketchbookPencilActiveCapability);
	Capabilities.Add(USketchbookPencilDeactiveCapability);
	Capabilities.Add(USketchbookPencilPivotRotationCapability);
	Capabilities.Add(USketchbookPencilTouchPaperCapability);
	Capabilities.Add(USketchbookPencilEraserTouchPaperCapability);
	Capabilities.Add(USketchbookPencilTravelToDrawableCapability);
	Capabilities.Add(USketchbookPencilApplyMovementCapability);

	// Sentence
	Components.Add(USketchbookPencilSentenceComponent);
	Capabilities.Add(USketchbookPencilDrawSentenceCapability);
	Capabilities.Add(USketchbookPencilEraseSentenceCapability);

	// Object
	Capabilities.Add(USketchbookPencilDrawObjectCapability);
	Capabilities.Add(USketchbookPencilEraseObjectCapability);

	// Prop Group
	Capabilities.Add(USketchbookPencilDrawPropGroupCapability);
	Capabilities.Add(USketchbookPencilErasePropGroupCapability);
};

struct FSketchbookPencilRequest
{
	USketchbookDrawableComponent Drawable;
	bool bErase;

	FSketchbookPencilRequest(USketchbookDrawableComponent InDrawable, bool bInErase)
	{
		Drawable = InDrawable;
		bErase = bInErase;
	}

	bool IsAlreadyFinished() const
	{
		if(bErase)
		{
			if(!Drawable.IsDrawnOrBeingDrawn())
				return true;
		}
		else
		{
			if(Drawable.IsDrawnOrBeingDrawn())
				return true;
		}

		return false;
	}

	bool WasInterrupted() const
	{
		return Drawable.WasInterrupted();
	}
};

enum ESketchbookPencilPivotState
{
	Drawing,
	Transitioning,
	Erasing,
};

UCLASS(Abstract)
class ASketchbookPencil : AHazeActor
{
	access Internal = private, USketchbookPencilEventHandler;

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostUpdateWork;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	access:Internal USceneComponent MeshTipRoot;

	UPROPERTY(DefaultComponent, Attach = MeshTipRoot)
	access:Internal USceneComponent MeshPivotRoot;

	UPROPERTY(DefaultComponent, Attach = MeshPivotRoot)
	access:Internal UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshPivotRoot)
	access:Internal UStaticMeshComponent ShadowMeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshPivotRoot)
	access:Internal USceneComponent EraserRoot;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(SketchbookPencilSheet);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;

	UPROPERTY(DefaultComponent)
	USketchbookPencilProjectionTemporalLogComponent ProjectionTemporalLogComp;
#endif

	UPROPERTY()
	UMaterialInterface SaveSpinnerOverride;

	bool bIsActive = false;
	private TArray<FSketchbookPencilRequest> RequestQueue;
	TOptional<FSketchbookPencilRequest> CurrentRequest;
	TOptional<FSketchbookPencilRequest> TravelToRequest;

	private FHazeAcceleratedVector AccPencilLocation;
	private uint LocationSetFrame = 0;
	private FInstigator LocationInstigator;

	private FHazeAcceleratedQuat AccPencilRotationOffset;
	private uint RotationOffsetSetFrame = 0;
	private FInstigator RotationOffsetInstigator;

	private FHazeAcceleratedVector AccTipOffset;
	private bool bTipTargetOnPaper = false;
	private uint TipLocationSetFrame = 0;
	private FInstigator TipLocationInstigator;

	private FHazeAcceleratedRotator AccTipRotationOffset;
	private uint TipRotationSetFrame = 0;
	private FInstigator TipRotationInstigator;

	// 0 is tip on paper, 1 is eraser on paper
	private float PivotRotationAlpha = 0;
	private uint PivotRotationSetFrame = 0;
	private FInstigator PivotRotationInstigator;
	private FVector InitialPivotRelativeLocation;

	private FQuat InitialRotation;
	FVector TipVelocity;

	private TArray<UMeshComponent> PencilMeshes;
	bool bAppliedSpinner = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRotation = ActorQuat;
		InitialPivotRelativeLocation = MeshPivotRoot.RelativeLocation;

		SetActorLocation(GetOutOfViewLocation());
		AccPencilLocation.SnapTo(ActorLocation);

		PencilMeshes.Add(MeshComp);
		PencilMeshes.Add(ShadowMeshComp);

		SceneView::SetViewportForcedAspectRatio(this, true);

		// Never allow the ubershader to be enabled during sketchbook, we're using the stencil value for the sketchbook postprocess
		for (auto Player : Game::Players)
		{
			auto PostProcessComp = UPostProcessingComponent::Get(Player);
			PostProcessComp.UberShaderEnablement.Apply(false, this, EInstigatePriority::Override);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto OverlayWidget = Cast<UGlobalHUDOverlayWidget>(Game::HazeGameInstance.GlobalHUDOverlay);
		if (OverlayWidget != nullptr)
			OverlayWidget.SaveSpinnerMaterial.Clear(this);

		SceneView::SetViewportForcedAspectRatio(this, false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateProjectionMatrix();

		if (!bAppliedSpinner)
		{
			auto OverlayWidget = Cast<UGlobalHUDOverlayWidget>(Game::HazeGameInstance.GlobalHUDOverlay);
			OverlayWidget.SaveSpinnerMaterial.Apply(SaveSpinnerOverride, this);

			bAppliedSpinner = true;
		}

#if !RELEASE
		{
			FTemporalLog TemporalLog = TEMPORAL_LOG(this);
			TemporalLog.Value("bIsActive", bIsActive);

			TemporalLog.Section("AccPencilLocation")
				.Point("Value", AccPencilLocation.Value)
				.DirectionalArrow("Velocity", AccPencilLocation.Value, AccPencilLocation.Velocity)
				.Value("Set This Frame", LocationSetFrame == Time::FrameNumber)
				.Value("Instigator", LocationInstigator)
			;

			TemporalLog.Section("AccPencilRotationOffset")
				.Value("Value", AccPencilRotationOffset.Value)
				.Value("Velocity", AccPencilRotationOffset.Value)
				.Value("Set This Frame", RotationOffsetSetFrame == Time::FrameNumber)
				.Value("Instigator", RotationOffsetInstigator)
			;

			TemporalLog.Section("AccTipOffset")
				.DirectionalArrow("Value", AccPencilLocation.Value, AccTipOffset.Value)
				.DirectionalArrow("Velocity", AccPencilLocation.Value + AccTipOffset.Value, AccTipOffset.Value, 10, 20)
				.Value("Set This Frame", TipLocationSetFrame == Time::FrameNumber)
				.Value("Instigator", TipLocationInstigator)
			;
			
			TemporalLog.Value("bTipTargetOnPaper", bTipTargetOnPaper);

			TemporalLog.Section("AccTipRotationOffset")
				.Value("Value", AccTipRotationOffset.Value)
				.Value("Velocity", AccTipRotationOffset.Value)
				.Value("Set This Frame", TipRotationSetFrame == Time::FrameNumber)
				.Value("Instigator", TipRotationInstigator)
			;

			TemporalLog.Section("PivotRotation")
				.Value("Alpha", PivotRotationAlpha)
				.Value("Set This Frame", PivotRotationSetFrame == Time::FrameNumber)
				.Value("Instigator", PivotRotationInstigator)
			;
		}

		if(HasControl())
		{
			FTemporalLog TemporalLog = TEMPORAL_LOG(this, "Requests");
			if(CurrentRequest.IsSet())
			{
				TemporalLog.Value("Current Request;Drawable", CurrentRequest.Value.Drawable);
				TemporalLog.Value("Current Request;bErase", CurrentRequest.Value.bErase);
			}
			else
			{
				TemporalLog.Value("Current Request;Is Set", false);
			}

			TemporalLog.Value("RequestQueue;Count", RequestQueue.Num());

			for(int i = 0; i < RequestQueue.Num(); i++)
			{
				TemporalLog.Value(f"RequestQueue;Request {i};Drawable", RequestQueue[i].Drawable);
				TemporalLog.Value(f"RequestQueue;Request {i};bErase", RequestQueue[i].bErase);
			}
		}
#endif
	}

	void SetShadowStencilValue(int Value)
	{
		ShadowMeshComp.SetCustomDepthStencilValue(Value);
	}

	void RequestDraw(FSketchbookPencilRequest Request)
	{
		if(!HasControl())
			return;

		check(!Request.bErase);
		RequestQueue.Add(Request);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "Requests");
		TemporalLog.Event(f"RequestDraw {Request.Drawable}");
#endif
	}

	void RequestErase(FSketchbookPencilRequest Request)
	{
		if(!HasControl())
			return;

		check(Request.bErase);
		RequestQueue.Add(Request);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "Requests");
		TemporalLog.Event(f"RequestDraw {Request.Drawable}");
#endif
	}

	void CancelCurrentDraw()
	{
		if(!HasControl())
			return;

		if(!CurrentRequest.IsSet())
			return;

		if(!CurrentRequest.Value.Drawable.IsDrawnOrBeingDrawn())
			return;

		CurrentRequest.Value.Drawable.Interrupt();
	}

	void CancelAllRequests(bool bOnlyDraws = false, bool bInterruptPencil = false)
	{
		if(!HasControl())
			return;

		if(bOnlyDraws)
		{
			for(int i = RequestQueue.Num() - 1; i >= 0; i--)
			{
				if(!RequestQueue[i].bErase)
					RequestQueue.RemoveAt(i);
			}
		}
		else
		{
			RequestQueue.Empty();
		}

		if(bInterruptPencil)
		{
			if(CurrentRequest.IsSet())
			{
				CurrentRequest.Value.Drawable.Interrupt();
			}
			
			if(TravelToRequest.IsSet())
			{
				TravelToRequest.Value.Drawable.Interrupt();
				TravelToRequest.Reset();
			}
		}
	}

	bool HasValidRequestInQueue() const
	{
		check(HasControl());
		
		for(int i = 0; i < RequestQueue.Num(); i++)
		{
			if(!RequestQueue[i].IsAlreadyFinished())
				return true;
		}

		return false;
	}

	void TrimInvalidRequestsFromStartOfQueue()
	{
		check(HasControl());

		int TrimCount = 0;
		while(!RequestQueue.IsEmpty() && RequestQueue[0].IsAlreadyFinished())
		{
			RequestQueue.RemoveAt(0);
			TrimCount++;
		}

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this, "Requests");
		TemporalLog.Event(f"Trimmed {TrimCount} invalid requests");
#endif
	}

	FSketchbookPencilRequest GetNextRequestInQueue() const
	{
		check(HasControl());

		return RequestQueue[0];
	}

	FSketchbookPencilRequest GetNextValidRequestInQueue() const
	{
		check(HasControl());

		for(int i = 0; i < RequestQueue.Num(); i++)
		{
			if(!RequestQueue[i].IsAlreadyFinished())
			{
				return RequestQueue[i];
			}
		}

		return RequestQueue[0];
	}

	FSketchbookPencilRequest PopNextRequestFromQueue()
	{
		check(HasControl());
		
		FSketchbookPencilRequest Request = GetNextRequestInQueue();
		RequestQueue.RemoveAt(0);
		return Request;
	}

	void OnStartDrawing(USketchbookDrawableComponent Drawable)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Event(f"Start Drawing {Drawable}");
#endif

		Drawable.StartBeingDrawn();
	}

	void OnStartErasing(USketchbookDrawableComponent Drawable)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Event(f"Start Erasing {Drawable}");
#endif

		Drawable.StartBeingErased();
	}

	void OnFinishedDrawing(USketchbookDrawableComponent Drawable)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Event(f"Finished Drawing {Drawable}");
#endif

		Drawable.FinishBeingDrawn();

		if(HasControl())
			CurrentRequest.Reset();
	}

	void OnFinishedErasing(USketchbookDrawableComponent Drawable)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Event(f"Finished Erasing {Drawable}");
#endif

		Drawable.FinishBeingErased();

		if(HasControl())
			CurrentRequest.Reset();
	}

	void OnInterrupted(USketchbookDrawableComponent Drawable)
	{
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Event(f"Interrupted while Drawing or Erasing {Drawable}");
#endif

		if(HasControl())
			CurrentRequest.Reset();
	}

	FVector GetOutOfViewLocation() const
	{
		AHazePlayerCharacter Player = SceneView::FullScreenPlayer;
		if(Player == nullptr)
			Player = Game::Zoe;

		FVector Origin;
		FVector Direction;
		SceneView::DeprojectScreenToWorld_Relative(Player, FVector2D(1.2, -0.2), Origin, Direction);

		FVector Intersection = Math::RayPlaneIntersection(Origin, Direction, FPlane(FVector::ZeroVector, FVector::ForwardVector));

		Intersection.X = -600;
		
		return Intersection;
	}

	void SnapPencilTo(FVector Target, FVector Velocity, FInstigator Instigator)
	{
		FVector PlaneTarget = Sketchbook::ProjectWorldLocationToPagePlane(Target);

		AccPencilLocation.SnapTo(PlaneTarget, Velocity);
		LocationSetFrame = Time::FrameNumber;
		LocationInstigator = Instigator;
	}

	void MoveLinearTo(FVector Target, float Speed, float DeltaTime, FInstigator Instigator)
	{
		FVector PlaneTarget = Sketchbook::ProjectWorldLocationToPagePlane(Target);

		FVector NewLocation = Math::VInterpConstantTo(AccPencilLocation.Value, PlaneTarget, DeltaTime, Speed);
		FVector NewVelocity = (NewLocation - AccPencilLocation.Value) / DeltaTime;
		AccPencilLocation.SnapTo(NewLocation, NewVelocity);
		
		LocationSetFrame = Time::FrameNumber;
		LocationInstigator = Instigator;
	}

	void MoveAccelerateTo(FVector Target, float Duration, float DeltaTime, FInstigator Instigator)
	{
		FVector PlaneTarget = Sketchbook::ProjectWorldLocationToPagePlane(Target);

		AccPencilLocation.AccelerateTo(PlaneTarget, Duration, DeltaTime);
		LocationSetFrame = Time::FrameNumber;
		LocationInstigator = Instigator;
	}

	FVector GetPencilLocation() const
	{
		return AccPencilLocation.Value;
	}

	void RotateOffsetTowards(FQuat Target, float Duration, float DeltaTime, FInstigator Instigator)
	{
		AccPencilRotationOffset.AccelerateTo(Target, Duration, DeltaTime);
		RotationOffsetSetFrame = Time::FrameNumber;
		RotationOffsetInstigator = Instigator;
	}

	void MoveTipOffsetLinearTo(FVector TargetOffset, float Speed, float DeltaTime, FInstigator Instigator)
	{
		check(TargetOffset.X < KINDA_SMALL_NUMBER, "Never move the tip to behind the paper!");

		FVector NewLocation = Math::VInterpConstantTo(AccTipOffset.Value, TargetOffset, DeltaTime, Speed);
		FVector NewVelocity = (NewLocation - AccTipOffset.Value) / DeltaTime;
		AccTipOffset.SnapTo(NewLocation, NewVelocity);

		bTipTargetOnPaper = Math::IsNearlyZero(TargetOffset.X);
		TipLocationSetFrame = Time::FrameNumber;
		TipLocationInstigator = Instigator;
	}

	void MoveTipOffsetAccelerateTo(FVector TargetOffset, float Duration, float DeltaTime, FInstigator Instigator)
	{
		check(TargetOffset.X < KINDA_SMALL_NUMBER, "Never move the tip to behind the paper!");

		AccTipOffset.AccelerateTo(TargetOffset, Duration, DeltaTime);
		bTipTargetOnPaper = Math::IsNearlyZero(TargetOffset.X);
		TipLocationSetFrame = Time::FrameNumber;
		TipLocationInstigator = Instigator;
	}

	void SnapTipOffsetTo(FVector TargetOffset, FInstigator Instigator)
	{
		check(TargetOffset.X < KINDA_SMALL_NUMBER, "Never move the tip to behind the paper!");

		AccTipOffset.SnapTo(TargetOffset);
		bTipTargetOnPaper = Math::IsNearlyZero(TargetOffset.X);
		TipLocationSetFrame = Time::FrameNumber;
		TipLocationInstigator = Instigator;
	}

	FVector GetCurrentTipOffset() const
	{
		return AccTipOffset.Value;
	}

	void RotateTipOffsetTowards(FRotator TargetOffset, float Duration, float DeltaTime, FInstigator Instigator)
	{
		AccTipRotationOffset.AccelerateTo(TargetOffset, Duration, DeltaTime);
		TipRotationSetFrame = Time::FrameNumber;
		TipRotationInstigator = Instigator;
	}

	float GetPivotRotationAlpha() const
	{
		return PivotRotationAlpha;
	}

	void SetPivotRotationAlpha(float InPivotRotationAlpha, FInstigator Instigator)
	{
		PivotRotationAlpha = InPivotRotationAlpha;
		PivotRotationSetFrame = Time::FrameNumber;
		PivotRotationInstigator = Instigator;
	}

	ESketchbookPencilPivotState GetPivotState() const
	{
		if(PivotRotationAlpha < KINDA_SMALL_NUMBER)
			return ESketchbookPencilPivotState::Drawing;
		else if(PivotRotationAlpha > 1.0 - KINDA_SMALL_NUMBER)
			return ESketchbookPencilPivotState::Erasing;
		else
			return ESketchbookPencilPivotState::Transitioning;
	}

	bool IsTipTouchingPaper() const
	{
		if(GetPivotState() != ESketchbookPencilPivotState::Drawing)
			return false;

		if(!bTipTargetOnPaper)
			return false;

		if(GetCurrentTipOffset().X < -5)
			return false;

		return true;
	}

	bool IsEraserTouchingPaper() const
	{
		if(GetPivotState() != ESketchbookPencilPivotState::Erasing)
			return false;

		if(!bTipTargetOnPaper)
			return false;

		if(GetCurrentTipOffset().X < -5)
			return false;

		return true;
	}

	FRotator GetCurrentTipRotationOffset() const
	{
		return AccTipRotationOffset.Value;
	}

	bool HasPencilMovedThisFrame() const
	{
		return LocationSetFrame == Time::FrameNumber;
	}

	bool HasPencilRotatedThisFrame() const
	{
		return RotationOffsetSetFrame == Time::FrameNumber;
	}

	bool HasTipMovedThisFrame() const
	{
		return TipLocationSetFrame == Time::FrameNumber;
	}

	bool HasTipRotatedThisFrame() const
	{
		return TipRotationSetFrame == Time::FrameNumber;
	}

	bool HasPivotRotatedThisFrame() const
	{
		return PivotRotationSetFrame == Time::FrameNumber;
	}

	void ApplyPencilMovement()
	{
		FVector Location = Sketchbook::ProjectWorldLocationToPagePlane(AccPencilLocation.Value);

		FVector Velocity = (Location - ActorLocation) / Time::GetActorDeltaSeconds(this);
		SetActorVelocity(Velocity);
		
		FQuat Rotation = AccPencilRotationOffset.Value * InitialRotation;
		SetActorLocationAndRotation(Location, Rotation);

		MeshTipRoot.SetWorldLocation(Location + AccTipOffset.Value);
		TipVelocity = Velocity + AccTipOffset.Velocity;
		MeshTipRoot.SetRelativeRotation(AccTipRotationOffset.Value);

		MeshPivotRoot.SetRelativeRotation(FQuat::Slerp(FQuat::Identity, FQuat(FVector::RightVector, PI), PivotRotationAlpha));

		float PivotLocationOffset = Math::Sin(PivotRotationAlpha * PI);
		MeshPivotRoot.SetRelativeLocation(InitialPivotRelativeLocation + FVector(PivotLocationOffset * 400, 0, 0));
	}

	void UpdateProjectionMatrix()
	{
		if (!SceneView::IsFullScreen())
			return;

		FVector2D FloatResolution = SceneView::GetConstrainedViewportResolution();
		UHazeViewPoint ViewPoint = SceneView::GetFullScreenPlayer().GetViewPoint();

		FHazeViewParameters OverlayViewParams;
		OverlayViewParams.Location = FVector::ZeroVector;
		OverlayViewParams.Rotation = ViewPoint.ViewRotation;
		OverlayViewParams.FOV = 70.0;
		OverlayViewParams.bConstrainAspectRatio = false;
		OverlayViewParams.ViewRectMin = FVector2D(0, 0);
		OverlayViewParams.ViewRectMax = FVector2D(1, 1);
		OverlayViewParams.ScreenResolution = FloatResolution;
		FHazeComputedView OverlayView = SceneView::ComputeView(OverlayViewParams);

		FHazeViewParameters PageViewParams;
		PageViewParams.Location = ViewPoint.ViewLocation;
		PageViewParams.Rotation = ViewPoint.ViewRotation;
		PageViewParams.FOV = ViewPoint.ViewFOV;
		PageViewParams.bConstrainAspectRatio = false;
		PageViewParams.ViewRectMin = FVector2D(0, 0);
		PageViewParams.ViewRectMax = FVector2D(1, 1);
		PageViewParams.ScreenResolution = FloatResolution;
		FHazeComputedView PageView = SceneView::ComputeView(PageViewParams);

		// Find the location on the page that the pen tip is hovering over
		FVector PenTipLocation = ActorLocation;
		FVector PageAnchorLocation = PenTipLocation.PointPlaneProject(Sketchbook::Projection::PagePlaneOrigin, Sketchbook::Projection::PagePlaneNormal);

		// Find the screen space location of the page anchor
		FVector2D Anchor_ScreenUV;
		PageView.ProjectWorldToViewUV(PageAnchorLocation, Anchor_ScreenUV);

		// Find the overlay space location to use that places the anchor at the same screen space position
		FVector Anchor_OverlayRayOrigin;
		FVector Anchor_OverlayRayDirection;
		OverlayView.DeprojectViewUVToWorld(Anchor_ScreenUV, Anchor_OverlayRayOrigin, Anchor_OverlayRayDirection);

		FVector Anchor_OverlaySpace = Anchor_OverlayRayOrigin + Anchor_OverlayRayDirection * Sketchbook::Projection::PageDepthInOverlayView;

		for (UMeshComponent PenMesh : PencilMeshes)
		{
			PenMesh.SetHiddenInGame(false);

			PenMesh.SetColorParameterValueOnMaterials(
				n"Overlay_Proj_PlaneX",
				FLinearColor(
					OverlayView.ViewProjMatrix.XPlane.X,
					OverlayView.ViewProjMatrix.XPlane.Y,
					OverlayView.ViewProjMatrix.XPlane.Z,
					OverlayView.ViewProjMatrix.XPlane.W,
				),
			);
			PenMesh.SetColorParameterValueOnMaterials(
				n"Overlay_Proj_PlaneY",
				FLinearColor(
					OverlayView.ViewProjMatrix.YPlane.X,
					OverlayView.ViewProjMatrix.YPlane.Y,
					OverlayView.ViewProjMatrix.YPlane.Z,
					OverlayView.ViewProjMatrix.YPlane.W,
				),
			);
			PenMesh.SetColorParameterValueOnMaterials(
				n"Overlay_Proj_PlaneZ",
				FLinearColor(
					OverlayView.ViewProjMatrix.ZPlane.X,
					OverlayView.ViewProjMatrix.ZPlane.Y,
					OverlayView.ViewProjMatrix.ZPlane.Z,
					OverlayView.ViewProjMatrix.ZPlane.W,
				),
			);
			PenMesh.SetColorParameterValueOnMaterials(
				n"Overlay_Proj_PlaneW",
				FLinearColor(
					OverlayView.ViewProjMatrix.WPlane.X,
					OverlayView.ViewProjMatrix.WPlane.Y,
					OverlayView.ViewProjMatrix.WPlane.Z,
					OverlayView.ViewProjMatrix.WPlane.W,
				),
			);

			PenMesh.SetColorParameterValueOnMaterials(
				n"Page_InvProj_PlaneX",
				FLinearColor(
					PageView.InvViewProjMatrix.XPlane.X,
					PageView.InvViewProjMatrix.XPlane.Y,
					PageView.InvViewProjMatrix.XPlane.Z,
					PageView.InvViewProjMatrix.XPlane.W,
				),
			);
			PenMesh.SetColorParameterValueOnMaterials(
				n"Page_InvProj_PlaneY",
				FLinearColor(
					PageView.InvViewProjMatrix.YPlane.X,
					PageView.InvViewProjMatrix.YPlane.Y,
					PageView.InvViewProjMatrix.YPlane.Z,
					PageView.InvViewProjMatrix.YPlane.W,
				),
			);
			PenMesh.SetColorParameterValueOnMaterials(
				n"Page_InvProj_PlaneZ",
				FLinearColor(
					PageView.InvViewProjMatrix.ZPlane.X,
					PageView.InvViewProjMatrix.ZPlane.Y,
					PageView.InvViewProjMatrix.ZPlane.Z,
					PageView.InvViewProjMatrix.ZPlane.W,
				),
			);
			PenMesh.SetColorParameterValueOnMaterials(
				n"Page_InvProj_PlaneW",
				FLinearColor(
					PageView.InvViewProjMatrix.WPlane.X,
					PageView.InvViewProjMatrix.WPlane.Y,
					PageView.InvViewProjMatrix.WPlane.Z,
					PageView.InvViewProjMatrix.WPlane.W,
				),
			);

			PenMesh.SetVectorParameterValueOnMaterials(
				n"World_AnchorLocation", PageAnchorLocation,
			);
			PenMesh.SetVectorParameterValueOnMaterials(
				n"Overlay_AnchorLocation", Anchor_OverlaySpace,
			);
		}

		// TESTING: Project the pen tip into overlay space
		// FVector TestLocation = PenTipLocation;
		// FVector PenTip_OverlaySpace = Anchor_OverlaySpace + (TestLocation - PageAnchorLocation);
		// FVector2D PenTip_ScreenUV;
		// OverlayView.ProjectWorldToViewUV(PenTip_OverlaySpace, PenTip_ScreenUV);

		// FVector PenTip_WorldOrigin, PenTip_WorldDirection;
		// PageView.DeprojectViewUVToWorld(PenTip_ScreenUV, PenTip_WorldOrigin, PenTip_WorldDirection);

		// Debug::DrawDebugSphere(TestLocation, 100.0, LineColor = FLinearColor::Red);
		// Debug::DrawDebugSphere(PenTip_WorldOrigin + PenTip_WorldDirection * 15000, 100.0, LineColor = FLinearColor::Green);
	}

	/**
	 * Returns -1 if not currently drawing
	 */
	UFUNCTION(BlueprintPure)
	float GetCurrentDrawAlpha() const
	{
		if(!CurrentRequest.IsSet())
			return -1;

		switch(CurrentRequest.Value.Drawable.GetState())
		{
			case ESketchbookDrawableState::NotDrawn:
				return 0;

			case ESketchbookDrawableState::BeingDrawn:
			case ESketchbookDrawableState::BeingErased:
			case ESketchbookDrawableState::Interrupted:
				return CurrentRequest.Value.Drawable.GetDrawnFraction();
			
			case ESketchbookDrawableState::Drawn:
				return 1;
		}
	}

#if EDITOR
	UFUNCTION(DevFunction)
	private void DevCancelAllDrawsAndInterrupt()
	{
		CancelAllRequests(true, true);
	}
#endif
};

namespace Sketchbook
{
	ASketchbookPencil GetPencil()
	{
		return TListedActors<ASketchbookPencil>().Single;
	}

	FVector ProjectWorldLocationToPagePlane(FVector WorldLocation)
	{
		if (!SceneView::IsFullScreen())
			return FVector(0, WorldLocation.Y, WorldLocation.Z);

		FVector ViewOrigin = SceneView::FullScreenPlayer.ViewLocation;
		FVector ViewDirection = WorldLocation - ViewOrigin;
		
		// FVector2D ViewpointRelativePosition;
		// SceneView::ProjectWorldToViewpointRelativePosition(SceneView::FullScreenPlayer, WorldLocation, ViewpointRelativePosition);

		// FVector Origin, Direction;
		// SceneView::DeprojectScreenToWorld_Relative(SceneView::FullScreenPlayer, ViewpointRelativePosition, Origin, Direction);

		FVector LocationOnPlane = Math::RayPlaneIntersection(ViewOrigin, ViewDirection, FPlane(Projection::PagePlaneOrigin, Projection::PagePlaneNormal));

		return LocationOnPlane;
	}

	/**
	 * Get the plane that the pencil is currently drawing
	 * DrawTangent should be an "orthogonal" vector to the drawing direction, (currently always 45 degrees)
	 */
	FPlane GetPencilPlane(FVector PencilLocation, FVector DrawNormal)
	{
		auto FullScreenPlayer = SceneView::FullScreenPlayer;

		FVector DrawTangent = FullScreenPlayer.ViewRotation.ForwardVector.CrossProduct(DrawNormal);
		
		// Calculate where the pencil is in UV space
		FVector2D PencilUV;
		SceneView::ProjectWorldToViewpointRelativePosition(FullScreenPlayer, PencilLocation, PencilUV);

		// Transform back to world space, specifically to get the direction
		FVector PencilOrigin, PencilDirection;
		SceneView::DeprojectScreenToWorld_Relative(FullScreenPlayer, PencilUV, PencilOrigin, PencilDirection);

		// Create a drawing plane using the new pencil direction
		// This will create a plane that takes the FOV into account
		FVector PlaneNormal = DrawTangent.CrossProduct(PencilDirection).GetSafeNormal();

		return FPlane(PencilLocation, PlaneNormal);
	}

	UFUNCTION(BlueprintCallable)
	void SketchbookCancelAllRequests(bool bOnlyDraws = false, bool bInterruptPencil = false)
	{
		Sketchbook::GetPencil().CancelAllRequests(bOnlyDraws, bInterruptPencil);
	}

	UFUNCTION(BlueprintCallable)
	void SketchbookRequestDrawActor(AHazeActor Actor)
	{
		if(Actor == nullptr)
			return;

		auto Drawable = USketchbookDrawableComponent::Get(Actor);
		if(Drawable == nullptr)
			return;

		Drawable.RequestDraw();
	}

	UFUNCTION(BlueprintCallable)
	void SketchbookRequestDrawActors(TArray<AHazeActor> Actors)
	{
		for(auto Actor : Actors)
			Sketchbook::SketchbookRequestDrawActor(Actor);
	}

	UFUNCTION(BlueprintCallable)
	void SketchbookRequestEraseActor(AHazeActor Actor)
	{
		if(Actor == nullptr)
			return;

		auto Drawable = USketchbookDrawableComponent::Get(Actor);
		if(Drawable == nullptr)
			return;

		Drawable.RequestErase();
	}

	UFUNCTION(BlueprintCallable)
	void SketchbookRequestEraseActors(TArray<AHazeActor> Actors)
	{
		for(auto Actor : Actors)
			Sketchbook::SketchbookRequestEraseActor(Actor);
	}
};