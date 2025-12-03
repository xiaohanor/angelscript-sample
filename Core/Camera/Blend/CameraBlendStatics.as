
enum ECameraBlendAlphaType
{
	Linear,
	EaseIn,
	EaseOut,
	EaseInOut,
	Accelerated,
	SinusoidalInOut,
	Curve,
};

namespace CameraBlend
{
	float GetBlendAlpha(ECameraBlendAlphaType AlphaType, FHazeCameraViewPointBlendInfo BlendInfo, FRuntimeFloatCurve Curve, float Exponential)
	{
		switch(AlphaType)
		{
			case ECameraBlendAlphaType::Linear:
				return BlendInfo.BlendAlpha;

			case ECameraBlendAlphaType::EaseIn:
				return Math::EaseIn(0, 1, BlendInfo.BlendAlpha, Exponential);
			
			case ECameraBlendAlphaType::EaseOut:
				return Math::EaseOut(0, 1, BlendInfo.BlendAlpha, Exponential);

			case ECameraBlendAlphaType::EaseInOut:
				return Math::EaseInOut(0, 1, BlendInfo.BlendAlpha, Exponential);

			case ECameraBlendAlphaType::Accelerated:
				return BlendInfo.AcceleratedBlendAlpha;

			case ECameraBlendAlphaType::SinusoidalInOut:
				return Math::SinusoidalInOut(0, 1, BlendInfo.BlendAlpha);

			case ECameraBlendAlphaType::Curve:
				return Curve.GetFloatValue(BlendInfo.BlendAlpha);
		}
	}
}