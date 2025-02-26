import { ComponentProps } from "react";
import NextImage from "next/image";

type Height = ComponentProps<typeof NextImage>["height"];
type Width = ComponentProps<typeof NextImage>["width"];

export default function Image({
  src,
  alt = "alt",
  width = 700,
  height = 400,
  ...props
}: ComponentProps<"img">) {
  if (!src) return null;
  return (
    <NextImage
      src={src}
      alt={alt}
      width={width as Width}
      height={height as Height}
      quality={40}
      className="w-full h-[400px] rounded-md border object-cover"
      {...props}
    />
  );
}
